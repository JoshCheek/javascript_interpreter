class JsSimulatedBlocking
  class Env
    def initialize(locals: {}, parent: NULL)
      self.parent, self.locals = parent, locals
    end

    attr_accessor :parent, :locals
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
  end
end
