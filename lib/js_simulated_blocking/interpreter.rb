require 'js_simulated_blocking/functions'
require 'js_simulated_blocking/callstack'

class JsSimulatedBlocking
  class Interpreter
    attr_accessor :stack, :instructions, :env

    def initialize(instructions:, env:)
      self.instructions = instructions
      self.env          = env
      self.stack        = Callstack.new
    end

    def result
      stack.peek
    end

    def local(name)
      env.resolve name
    end

    def call
      env                = self.env
      current_offset     = 0
      function_locations = []

      puts "-----  BEGIN  -----"
      require 'pp'
      pp stack
      while instruction = instructions[current_offset]
        instruction, *args = instruction
        puts "\n-----"
        pp stack
        puts "#{current_offset} #{instruction.inspect} #{args.inspect}"
        case instruction
        when :push
          to_push = args.first
          to_push = to_push.dup unless to_push.frozen?
          stack.push to_push
        when :resolve
          name  = stack.pop
          value = env.resolve name
          stack.push value
        when :declare_var
          name  = stack.pop
          value = stack.pop
          # guessing I put the objects onto the stack in the wrong order for this one >.<
          env.declare name, value
        when :declare_arg
          name  = stack.pop
          value = stack.peek.pop
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
          prototype        = env.new_object
          function         = Function.new(env, beginning_offset, ending_offset, prototype)
          stack.push(function)
        when :push_location
          stack.push current_offset
        when :push_env
          stack.push env
        when :pop_env
          env = stack.pop
          if !env.kind_of?(JsSimulatedBlocking::Env)
            instructions.map.with_index { |instr, index| [index, *instr] }
            require "pry"
            binding.pry
          end
        when :swap_top
          swap_top
        when :push_array # TODO: rename this to array_append
          element = stack.pop
          array   = stack.peek
          array.push element
        when :function_invoke
          env, current_offset = function_invoke
        when :function_internal
          function = stack.pop
          args     = stack.pop
          function.call(args)
        when :return, :function_end
          current_offset = stack.pop
          unless current_offset.kind_of? Fixnum
            require "pry"
            binding.pry
          end
        when :dot_access
          name   = stack.pop
          obj    = stack.pop
          method = obj.fetch name
          stack.push method
        when :new_object
          constructor = stack.pop
          obj         = env.new_object constructor: constructor, __proto__: constructor.prototype
          args        = stack.peek
          # args.unshift obj # Not tested: unshift vs push
          stack.push constructor
          env, current_offset = function_invoke
          stack.push obj
        else
          print "\e[41;37m#{{instruction: instruction, args: args}.inspect}\e[0m\n"
          require "pry"
          binding.pry
        end
        current_offset += 1
      end
      self
    end

    def function_invoke
      function = stack.pop
      env      = Env.new locals: {}, parent: function.env
      stack.push function if function.internal?
      [env, function.beginning]
    end

    def swap_top
      first  = stack.pop
      second = stack.pop
      stack.push first
      stack.push second
    end
  end
end
