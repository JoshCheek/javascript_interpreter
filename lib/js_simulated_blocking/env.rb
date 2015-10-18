require 'js_simulated_blocking/data_structures'

class JsSimulatedBlocking
  class Env
    attr_accessor :this, :parent, :locals

    def initialize(this:, locals: {}, parent: NULL)
      self.this   = this
      self.parent = parent
      self.locals = locals
    end

    def resolve(name)
      locals.fetch(name) { parent.resolve name }
    end

    def declare(name, value)
      locals[name] = value
      self
    end

    def all_visible
      parent.all_visible.merge locals
    end

    def new_function(**args, &block)
      args[:env] ||= self
      parent.new_function(**args, &block)
    end

    def new_internal_function(**args, &block)
      args[:env] ||= self
      parent.new_internal_function(**args, &block)
    end

    def new_object(**args)
      parent.new_object(**args)
    end

    def inspect(internal=false)
      if internal
        "#{locals.keys.inspect} -> #{parent.inspect true}"
      else
        "#<#{classname} keys=#{inspect true}>"
      end
    end

    def pretty_print(q, internal=false)
      if internal
        q.group do
          locals.keys.pretty_print q
          q.text '->'
          parent.pretty_print q, true
        end
      else
        q.group 1, "#<#{classname} ", ">" do
          q.text 'keys'
          q.text '='
          pretty_print q, true
        end
      end
    end

    private

    def classname
      self.class.to_s.sub 'JsSimulatedBlocking::', ''
    end
  end

  module Env::NULL
    extend self
    def locals()      {}     end
    def parent()      self   end
    def all_visible() locals end

    def resolve(name)
      raise "No variable named: #{name.inspect}"
    end

    def declare(name, value)
      raise "Cannot declare variables to the null env! #{name.inspect}, #{value.inspect}"
    end

    def default_prototype
      @default_prototype ||= JsObject.new
    end

    def new_object(**args)
      # maybeh?
      # args[:constructor] = Object
      # args[:prototype]   = ??
      JsObject.new **args
    end

    def new_internal_function(**args, &block)
      args[:env]       ||= self
      args[:prototype] ||= new_object
      InternalFunction.new **args, &block
    end

    def new_function(**args, &block)
      args[:env] ||= self
      Function.new **args, &block
    end

    def inspect(internal)
      "Env::NULL"
    end

    def pretty_print(q, internal)
      q.text inspect(internal)
    end
  end
end
