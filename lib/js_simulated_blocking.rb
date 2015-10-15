require 'rkelly'
require 'js_simulated_blocking/env'
require 'js_simulated_blocking/parse'


class JsSimulatedBlocking
  Function = Struct.new :env, :beginning, :ending

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

    # puts "-----  BEGIN  -----"
    while expr = exprs[current_offset]
      instruction, *args = expr
      # p offset: current_offset, instruction: expr
      case instruction
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
        function         = Function.new(env, beginning_offset, ending_offset)
        stack.push(function)
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
        current_offset = stack.pop
      else
        print "\e[41;37m#{{instruction: instruction, args: args}.inspect}\e[0m\n"
        require "pry"
        binding.pry
      end
      current_offset += 1
    end
  end
end
