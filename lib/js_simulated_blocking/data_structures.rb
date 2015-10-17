class JsSimulatedBlocking
  class JsObject
    attr_accessor :constructor, :__proto__, :hash

    def initialize(constructor: nil, __proto__: nil)
      self.constructor = constructor
      self.__proto__   = __proto__
      self.hash        = {}
    end

    def []=(key, value)
      hash[key] = value
    end

    def fetch(*args, &block)
      hash.fetch *args, &block
    end
  end

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

    def initialize(env:, name: nil, &block)
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
