require 'js_simulated_blocking/env'

class JsSimulatedBlocking
  Function = Struct.new :env, :beginning, :ending do
    def internal?
      false
    end

    def inspect
      "#<#{self.class.to_s.sub 'JsSimulatedBlocking::', ''} #{beginning}-#{ending} env locals: #{env.all_visible.keys.inspect}>"
    end
  end

  class InternalFunction < Function
    BEGINNING = 0
    ENDING    = 2

    attr_accessor :name, :block, :keys

    def initialize(name: nil, env: Env.new, &block)
      self.keys  = {}
      self.name  = name
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
