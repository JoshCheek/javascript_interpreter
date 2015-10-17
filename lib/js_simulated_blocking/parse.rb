require 'rkelly'
require 'js_simulated_blocking/errors'
require 'js_simulated_blocking/instructions'

# Reference: https://github.com/nene/rkelly-remix/blob/5034089bc821d61dbcb3472894177a293f1755a8/lib/rkelly/visitors/visitor.rb
class JsSimulatedBlocking
  class Parse
    def self.string(raw_js)
      if ast=RKelly::Parser.new.parse(raw_js)
        new(Instructions.new, ast).call.instructions.to_a
      else
        # RKelly raises for some errors, and for others just returns nil
        raise RKelly::SyntaxError, "parser did not return an ast"
      end
    rescue RKelly::SyntaxError => err
      raise JsSimulatedBlocking::SyntaxError, err.message
    end

    attr_accessor :instructions, :ast

    def initialize(instructions, ast)
      self.instructions, self.ast = instructions, ast
    end

    def call
      if instructions.empty?
        instructions.setup
        accept ast
      end
      self
    end

    def accept(target)
      target.accept(self)
    end

    def visit_SourceElementsNode(node)
      node.value.each { |value| accept value }
    end

    def visit_AddNode(node)
      accept node.left
      accept node.value
      instructions.add
    end

    def visit_VarStatementNode(node)
      node.value.each do |decl|
        if decl.constant?
          raise "Haven't checked this out yet: #{decl.to_sexp.inspect}"
        elsif !decl.value
          raise "Handle this situation! (should be undefined)"
        end
        assignment = decl.value
        accept assignment.value
        instructions.push decl.name.to_s.intern
        instructions.declare_var
      end
    end

    def visit_FunctionExprNode(node)
      begin_offset = instructions.next_offset
      instructions.function_begin -1
      node.arguments.each.with_index do |arg, index|
        instructions.push arg.value.intern
        instructions.declare_arg index
      end
      accept node.function_body.value
      instructions.function_end begin_offset
    end

    def visit_FunctionCallNode(node)
      surround :push_fn_call, :pop_fn_call do
        # TODO: set `this`
        accept node.value
        instructions.set_function

        instructions.push_env
        instructions.set_retenv

        node.arguments.value.each.with_index do |arg, index|
          accept arg
          instructions.set_arg index
        end

        instructions.set_return_location do
          instructions.function_invoke
        end
      end
    end

    def visit_TrueNode(node)    instructions.push true               end
    def visit_FalseNode(node)   instructions.push false              end
    def visit_NullNode(node)    instructions.push nil                end
    def visit_StringNode(node)  instructions.push node.value[1...-1] end # shitty escaping >.<
    def visit_NumberNode(node)  instructions.push node.value.to_f    end

    def visit_ResolveNode(node)
      instructions.push node.value.intern
      instructions.resolve
    end

    def visit_ReturnNode(node)
      if node.value
        accept(node.value)
        instructions.set_retval
        instructions.return
      else
        # apparently "undefined" should be returned
        require "pry"
        binding.pry
        instructions.return
      end
    end

    def visit_ParentheticalNode(node)
      accept node.value
    end

    def visit_ExpressionStatementNode(node)
      accept node.value
    end

    def visit_DotAccessorNode(node)
      accept node.value
      instructions.push node.accessor.intern
      instructions.dot_access
    end

    def visit_NewExprNode(node)
      surround :push_fn_call, :pop_fn_call do
        accept node.value
        instructions.set_function

        instructions.push_env
        instructions.set_retenv

        node.arguments.value.each.with_index do |arg, index|
          accept arg
          instructions.set_arg index
        end

        instructions.set_return_location do
          instructions.new_object
          instructions.function_invoke
        end

        instructions.copy_this
        instructions.swap_top
        instructions.set_retval
      end
    end

    def surround(pre, post, &block)
      instructions.__send__ pre
      block.call
      instructions.__send__ post
    end
  end
end
