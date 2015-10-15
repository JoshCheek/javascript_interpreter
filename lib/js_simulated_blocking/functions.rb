require 'js_simulated_blocking/env'

class JsSimulatedBlocking
  Function = Struct.new :env, :beginning, :ending do
    def internal?
      false
    end
  end

  class InternalFunction < Function
    BEGINNING = 0
    ENDING    = 2

    attr_accessor :block

    def initialize(env: Env.new, &block)
      self.block = block
      super env, BEGINNING, ENDING
    end

    def internal?
      true
    end

    def call(args)
      instance_exec args, &block
    end
  end
end
