require 'rkelly'
require 'js_simulated_blocking/errors'

class JsSimulatedBlocking
  def self.from_string(raw_js, stdout:)
    parser = RKelly::Parser.new
    # RKelly raises for some errors, and for others just returns nil
    ast = parser.parse(raw_js) or
      raise RKelly::SyntaxError, "parser did not return an ast"
    JsSimulatedBlocking.new ast: ast, stdout: stdout
  rescue RKelly::SyntaxError => err
    raise JsSimulatedBlocking::SyntaxError, err.message
  end


  attr_accessor :ast, :stdout, :result

  def initialize(ast:, stdout:)
    self.ast, self.stdout = ast, stdout
    self.result = nil
  end

  def call
    self.result = interpret_sexp ast.to_sexp
  end

  private

  def interpret_sexp(sexp)
    if sexp.first.kind_of? Array
      return sexp.inject nil do |_, child|
        interpret_sexp child
      end
    end

    type, *rest = sexp

    case type
    when :expression
      rest.inject nil do |_, child|
        interpret_sexp child
      end
    when :lit
      rest.first.to_f
    when :add
      left, right = rest.map { |child|
        interpret_sexp child
      }
      left + right
    else raise "What to do with AST: #{type.inspect}"
    end
  end
end
