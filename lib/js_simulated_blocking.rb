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
    sexp.first.kind_of? Array and
      return sexp.inject(nil) { |_, child| interpret_sexp child }

    type, *rest = sexp
    case type
    when :expression then rest.inject(nil) { |_, child| interpret_sexp child }
    when :str        then unescape_string rest.first
    when :lit        then rest.first.to_f
    when :add        then rest.map { |child| interpret_sexp child }.inject(:+)
    else raise "What to do with AST: #{type.inspect}"
    end
  end

  # ehh, good enough for now, seems like the parser should handle this, though
  def unescape_string(string)
    string[1...-1]
  end
end
