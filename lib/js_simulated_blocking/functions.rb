require 'js_simulated_blocking/env'

class JsSimulatedBlocking
  Function = Struct.new :env, :beginning, :ending, :prototype do
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

    attr_accessor :name, :block

    def initialize(name: nil, env: Env.new, &block)
      self.name  = name
      self.block = block
      prototype = :FIXME_where_to_get_this?
      super env, BEGINNING, ENDING, prototype
    end

    def internal?
      true
    end

    def call(args)
      instance_exec args, &block
    end
  end
end
