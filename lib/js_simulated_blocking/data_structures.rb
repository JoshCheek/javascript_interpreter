class JsSimulatedBlocking
  class JsObject
    attr_accessor :constructor, :__proto__, :hash

    def initialize(constructor: nil, __proto__: nil, hash: {})
      self.constructor = constructor
      self.__proto__   = __proto__
      self.hash        = hash
    end

    def []=(key, value)
      hash[key] = value
    end

    def fetch(*args)
      hash.fetch *args do
        __proto__.fetch *args
      end
    end

    def set_internal(attributes)
      internal_data.merge! attributes
    end

    def get_internal(key)
      internal_data.fetch key
    end

    private

    def internal_data
      @internal_data ||= {}
    end
  end

  class Function < JsObject
    attr_accessor :env, :beginning, :ending, :prototype

    def initialize(env:, beginning:, ending:, prototype:, **rest)
      self.env       = env
      self.beginning = beginning
      self.ending    = ending
      self.prototype = prototype
      super **rest
    end

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

    def initialize(name: nil, **rest, &block)
      self.name  = name
      self.block = block
      super beginning: BEGINNING, ending: ENDING, **rest
    end

    def internal?
      true
    end

    def call(args)
      instance_exec args, &block
    end
  end
end
