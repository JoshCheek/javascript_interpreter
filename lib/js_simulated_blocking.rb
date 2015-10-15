require 'js_simulated_blocking/env'
require 'js_simulated_blocking/parse'
require 'js_simulated_blocking/interpreter'

class JsSimulatedBlocking
  attr_accessor :interpreter
  def initialize(instructions:, stdout:)
    self.interpreter = Interpreter.new(
      instructions: instructions,
      stdout:       stdout,
      env:          Env.new,
    )
  end

  def call
    interpreter.call
  end
end
