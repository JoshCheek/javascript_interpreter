require 'js_simulated_blocking/env'

class JsSimulatedBlocking
  Function = Struct.new :env, :beginning, :ending do
    def internal?
      false
    end

    def inspect
      "#<#{classname} #{beginning}-#{ending} env-locals: #{env.all_visible.keys.inspect}>"
    end

    def pretty_print(q)
      q.group 1, "#<#{classname} ", ">" do
        q.text beginning.to_s
        q.text "-"
        q.text ending.to_s
        q.text " "
        q.text "locals"
        q.text "="
        q.text "["
        env.all_visible.keys.each_with_index do |key, index|
          q.text ', ' unless index.zero?
          key.pretty_print q
        end
        q.text "]"
      end
    end

    private

    def classname
      self.class.to_s.sub 'JsSimulatedBlocking::', ''
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
