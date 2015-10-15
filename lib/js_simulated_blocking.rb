require 'rkelly'
require 'js_simulated_blocking/parse'


class JsSimulatedBlocking
  class Function
    attr_accessor :env, :beginning, :ending
    def initialize(env:, beginning:, ending:)
      self.env, self.beginning, self.ending = env, beginning, ending
    end
  end

  class Env
    NULL = Module.new
    NULL.extend NULL

    attr_accessor :parent, :locals
    def NULL.parent() self end
    def NULL.locals() {}   end

    def initialize(locals: {}, parent: NULL)
      self.parent, self.locals = parent, locals
    end

    def resolve(name)
      locals.fetch(name) { parent.resolve name }
    end
    def NULL.resolve(name)
      raise "No variable named: #{name.inspect}"
    end

    def declare(name, value)
      locals[name] = value
    end
    def NULL.declare(name, value)
      raise "Cannot declare variables to the null env! #{{name: name, value: value}.inspect}"
    end

    def all_visible
      parent.all_visible.merge locals
    end
    def NULL.all_visible
      locals
    end
  end
end


class JsSimulatedBlocking
  attr_accessor :stdout, :stack, :instructions, :env

  # TODO: rename sexp -> instructions
  def initialize(sexp:, stdout:)
    self.instructions = sexp
    self.stdout       = stdout
    self.stack        = []
    self.env          = Env.new
  end

  def call
    interpret_exprs instructions
    self
  end

  def result
    stack.last
  end

  private

  def interpret_exprs(exprs)
    env                = self.env
    current_offset     = 0
    function_locations = []
    current_result     = :no_result_was_set

    # puts "-----  BEGIN  -----"
    while expr = exprs[current_offset]
      instruction, *args = expr
      # p offset: current_offset, instruction: expr
      current_result = case instruction
      when :push
        stack.push args.first
      when :resolve
        name  = stack.pop
        value = env.resolve name
        stack.push value
      when :declare_var
        name  = stack.pop
        value = stack.pop
        env.declare name, value
      when :declare_arg
        name  = stack.pop
        value = stack.last.pop
        env.declare name, value
      when :pop
        stack.pop
      when :add
        right = stack.pop
        left  = stack.pop
        added = left + right
        stack.push added
        added
      when :begin_function
        ending_offset    = args.first
        beginning_offset = current_offset
        current_offset   = ending_offset
        stack.push Function.new(
          env:       env,
          beginning: beginning_offset,
          ending:    ending_offset,
        )
      when :push_location
        stack.push current_offset
      when :push_env
        stack.push env
      when :pop_env
        env = stack.pop
      when :swap_top
        first  = stack.pop
        second = stack.pop
        stack.push first
        stack.push second
      when :push_array
        element = stack.pop
        array   = stack.last
        array.push element
      when :invoke
        function       = stack.pop
        env            = Env.new locals: {}, parent: function.env
        current_offset = function.beginning
      when :return
        if !stack.last.kind_of?(Fixnum)
          require "pry"
          binding.pry
        end
        current_offset = stack.pop
      else
        print "\e[41;37m#{{instruction: instruction, args: args}.inspect}\e[0m\n"
        require "pry"
        binding.pry
      end

      begin
        current_offset += 1
      rescue
        require "pry"
        binding.pry
      end
    end
    current_result
  end
end
