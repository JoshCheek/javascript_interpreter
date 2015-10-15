require 'js_simulated_blocking/env'
require 'js_simulated_blocking/parse'
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
