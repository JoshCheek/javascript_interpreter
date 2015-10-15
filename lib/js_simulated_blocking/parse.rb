require 'js_simulated_blocking/errors'

# Reference: https://github.com/nene/rkelly-remix/blob/5034089bc821d61dbcb3472894177a293f1755a8/lib/rkelly/visitors/visitor.rb
class JsSimulatedBlocking
  class Parse
    def self.string(raw_js, **initialization_attrs)
      sexp = string_to_sexp raw_js
      JsSimulatedBlocking.new sexp: sexp, **initialization_attrs
    rescue RKelly::SyntaxError => err
      raise JsSimulatedBlocking::SyntaxError, err.message
    end

    def self.string_to_sexp(raw_js)
      if ast=RKelly::Parser.new.parse(raw_js)
        new([], ast).call.sexp
      else
        # RKelly raises for some errors, and for others just returns nil
        raise RKelly::SyntaxError, "parser did not return an ast"
      end
    end

    attr_accessor :sexp, :ast

    def initialize(sexp, ast)
      self.sexp, self.ast = sexp, ast
    end

    def call
      self.sexp = accept ast if sexp.empty?
      self
    end

    def accept(target)
      target.accept(self)
    end

    def visit_SourceElementsNode(node)
      elements = node.value.map { |value| accept value }
      [:elements, *elements]
    end

    def visit_AddNode(node)
      [:add, accept(node.left), accept(node.value)]
    end

    def visit_VarStatementNode(node)
      declarations = node.value.map do |decl|
        decl.constant? and raise "Haven't checked this out yet: #{decl.to_sexp.inspect}"
        sexp       = [decl.name.to_s.intern]
        assignment = decl.value
        sexp << accept(assignment.value) if assignment
        sexp
      end
      [:vars, *declarations]
    end

    def visit_FunctionExprNode(node)
      body = accept node.function_body.value
      args = node.arguments.map(&:value).map(&:intern)
      [:function, args, body]
    end

    def visit_FunctionCallNode(node)
      receiver  = accept node.value
      arguments = node.arguments.value.map { |arg| accept arg }
      [:function_call, receiver, arguments]
    end

    def visit_TrueNode(*)  [:true]  end
    def visit_FalseNode(*) [:false] end
    def visit_NullNode(*)  [:null]  end

    def visit_StringNode(node)  [:string,  node.value[1...-1]]      end # shitty escaping >.<
    def visit_NumberNode(node)  [:number,  node.value.to_f]         end
    def visit_ResolveNode(node) [:resolve, node.value.intern]       end
    def visit_ReturnNode(node)  [:return,  accept(node.value)] end

    def visit_ParentheticalNode(node)       accept node.value end
    def visit_ExpressionStatementNode(node) accept node.value end
  end
end
