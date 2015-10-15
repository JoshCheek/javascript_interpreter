require 'js_simulated_blocking/errors'

# Reference: https://github.com/nene/rkelly-remix/blob/5034089bc821d61dbcb3472894177a293f1755a8/lib/rkelly/visitors/visitor.rb
class JsSimulatedBlocking
  class Instructions
    attr_accessor :instructions

    def initialize
      self.instructions = []
    end

    def to_a
      instructions
    end

    def empty?
      instructions.empty?
    end

    def self.instruction(name, &body)
      define_method name do |*args|
        instructions << instance_exec(*args, &body)
        self
      end
    end

    def current_offset
      next_offset - 1
    end

    def next_offset
      instructions.length
    end

    instruction(:push)            { |obj| [:push, obj] }
    instruction(:push_location)   { [:push_location] }
    instruction(:push_array)      { [:push_array] }
    instruction(:push_env)        { [:push_env] }
    instruction(:pop_env)         { [:pop_env] }
    instruction(:invoke)          { [:invoke] }
    instruction(:declare_var)     { [:declare_var] }
    instruction(:declare_arg)     { [:declare_arg] }
    instruction(:pop)             { [:pop] }
    instruction(:add)             { [:add] }
    instruction(:return)          { [:return] }
    instruction(:resolve)         { [:resolve] }
    instruction(:swap_top)        { [:swap_top] }

    instruction :begin_function do
      [:begin_function, -1]
    end

    instruction :end_function do |beginning_offset|
      instructions[beginning_offset][-1] = next_offset
      [:end_function]
    end
  end

  class Parse
    def self.string(raw_js, **initialization_attrs)
      sexp = string_to_sexp raw_js
      JsSimulatedBlocking.new sexp: sexp, **initialization_attrs
    rescue RKelly::SyntaxError => err
      raise JsSimulatedBlocking::SyntaxError, err.message
    end

    def self.string_to_sexp(raw_js)
      if ast=RKelly::Parser.new.parse(raw_js)
        instructions = Instructions.new
        new(instructions, ast).call
        instructions.to_a
      else
        # RKelly raises for some errors, and for others just returns nil
        raise RKelly::SyntaxError, "parser did not return an ast"
      end
    end

    attr_accessor :instructions, :ast

    def initialize(instructions, ast)
      self.instructions, self.ast = instructions, ast
    end

    def call
      accept ast if instructions.empty?
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
      offset = instructions.next_offset
      instructions.begin_function
      node.arguments.each { |arg|
        instructions.push arg.value.intern
        instructions.declare_arg
      }
      instructions.pop # args that are no longer being used
      accept node.function_body.value
      instructions.end_function offset
    end

    def visit_FunctionCallNode(node)
      # push the current environment
      instructions.push_env

      # placeholder for the return location
      retloc_index = instructions.next_offset
      instructions.push :placeholder

      # find the function
      accept node.value

      # push the args into an array
      instructions.push []
      node.arguments.value.each do |arg|
        accept arg              # push the arg
        instructions.push_array # onto the array
      end

      # function is on the top of the stack
      instructions.swap_top

      # invoke the function
      instructions.invoke

      # calculate the number of instructions
      if [:push, :placeholder] != instructions.instructions[retloc_index]
        require "pry"
        binding.pry
      end

      # update the return location
      instructions.instructions[retloc_index][-1] = instructions.current_offset

      # swap the env and the return value
      instructions.swap_top

      # update the env
      instructions.pop_env
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
        instructions.swap_top
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
  end
end