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
  def initialize(instructions:, stdout:, time:)
    object_function = InternalFunction.new(
      name:        'Object'.freeze,
      constructor: :FIXME,
      __proto__:   :FIXME,
      env:         :FIXME,
      prototype:   :FIXME,
    ) { |fn_call|
      require "pry"
      binding.pry
    }

    toplevel_object = JsObject.new(constructor: object_function, __proto__: nil)
    global_env      = Env.new this: toplevel_object

    Stdlib.global(stdout: stdout, time: time, env: global_env)

    self.interpreter = Interpreter.new(
      instructions: instructions,
      env:          global_env,
    )
  end

  def call
    interpreter.call
  end
end
