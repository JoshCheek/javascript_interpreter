require 'rkelly'

class JsSimulatedBlocking
  def self.from_string(raw_js, stdout:)
    parser = RKelly::Parser.new
    ast    = parser.parse(raw_js)
    ast || raise(RKelly::SyntaxError, "parser did not return an ast")
    JsSimulatedBlocking.new(ast, stdout: $stdout)
  rescue RKelly::SyntaxError => err
    $stderr.puts "Syntax error (#{err.message})"
    exit 1
  end

  def call
  end
end
