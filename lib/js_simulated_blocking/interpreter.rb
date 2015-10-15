require 'js_simulated_blocking/functions'

class JsSimulatedBlocking
  class Interpreter
    attr_accessor :stack, :instructions, :env

    def initialize(instructions:, env:)
      self.instructions = instructions
      self.env          = env
      self.stack        = []
    end

    def result
      stack.last
    end

    def call
      env                = self.env
      current_offset     = 0
      function_locations = []

      # puts "-----  BEGIN  -----"
      while instruction = instructions[current_offset]
        instruction, *args = instruction
        # p offset: current_offset, instruction: instruction
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
        when :function_begin
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
        when :function_invoke
          function       = stack.pop
          env            = Env.new locals: {}, parent: function.env
          current_offset = function.beginning
          stack.push function if function.internal?
        when :function_internal
          function = stack.pop
          args     = stack.pop
          function.call(args)
        when :return, :function_end
          current_offset = stack.pop
        when :dot_access
          name   = stack.pop
          obj    = stack.pop
          method = obj.fetch name
          stack.push method
        else
          print "\e[41;37m#{{instruction: instruction, args: args}.inspect}\e[0m\n"
          require "pry"
          binding.pry
        end
        current_offset += 1
      end
      self
    end

  end
end
