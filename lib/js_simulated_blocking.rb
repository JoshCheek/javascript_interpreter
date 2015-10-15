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


  attr_accessor :ast, :stdout

  def initialize(ast:, stdout:)
    self.ast, self.stdout = ast, stdout
  end

  def call
    case ast
    when RKelly::Nodes::SourceElementsNode
      require "pry"
      binding.pry
    else raise "What to do with AST: #{ast.class}"
    end
  end
end
