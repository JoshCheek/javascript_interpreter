require 'rkelly'
require 'js_simulated_blocking/syntax_error'

class JsSimulatedBlocking
  def self.from_string(raw_js, stdout:)
    parser = RKelly::Parser.new
    ast    = parser.parse(raw_js)
    raise RKelly::SyntaxError, "parser did not return an ast" unless ast
    JsSimulatedBlocking.new ast, stdout: stdout
  rescue RKelly::SyntaxError => err
    raise JsSimulatedBlocking::SyntaxError, "Syntax error (#{err.message})"
  end

  def call
  end
end
