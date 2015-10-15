require 'js_simulated_blocking/parse'
require 'js_simulated_blocking/stdlib'
require 'js_simulated_blocking/interpreter'

class JsSimulatedBlocking
  def self.eval(raw_js, **initialization_attrs)
    JsSimulatedBlocking.new(
      instructions: Parse.string(raw_js),
      **initialization_attrs
    ).call
  end

  attr_accessor :interpreter
  def initialize(instructions:, stdout:)
    global_env = Stdlib.global(stdout: stdout)

    self.interpreter = Interpreter.new(
      instructions: instructions,
      env:          global_env,
    )
  end

  def call
    interpreter.call
  end
end
