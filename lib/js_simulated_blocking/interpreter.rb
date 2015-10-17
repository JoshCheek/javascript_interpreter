require 'js_simulated_blocking/data_structures'
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

      # puts "-----  BEGIN  -----"
      # require 'pp'
      # pp stack
      while instruction = instructions[current_offset]
        instruction, *args = instruction
        # puts "\n-----"
        # pp stack
        # puts "#{current_offset} #{instruction.inspect} #{args.inspect}"
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
          value = value.return_value if value.respond_to? :return_value
          env.declare name, value
        when :declare_arg
          name       = stack.pop
          fn_call    = stack.peek
          arg_offset = args[0]
          value      = fn_call.arguments[arg_offset]
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
        when :push_env
          stack.push env
        when :swap_top
          swap_top
        when :function_invoke
          env, current_offset = function_invoke
        when :function_internal
          fn_call  = stack.peek
          function = fn_call.function
          function.call(fn_call)
        when :return, :function_end
          fn_call        = stack.peek
          current_offset = fn_call.return_location
        when :dot_access
          name   = stack.pop
          obj    = stack.pop
          method = obj.fetch name
          stack.push method
        when :new_pre
          fn_call      = stack.peek
          fn           = fn_call.function
          obj          = env.new_object constructor: fn, __proto__: fn.prototype
          fn_call.this = obj
          env, current_offset = function_invoke
        when :new_post
          fn_call = stack.peek
          fn_call.return_value = fn_call.this
        when :push_fn_call
          # TODO: move this class to functions.rb
          function_call_class =
            Struct.new :function,
                       :arguments,
                       :return_env,
                       :return_location,
                       :return_value,
                       :this
          function_call = function_call_class.new
          function_call.arguments = []
          stack.push function_call
        when :pop_fn_call
          fn_call = stack.pop
          env     = fn_call.return_env
          stack.push fn_call.return_value
        when :set_function
          fn      = stack.pop
          fn_call = stack.peek
          fn_call.function = fn
        when :set_retenv
          return_env = stack.pop
          fn_call    = stack.peek
          fn_call.return_env = return_env
        when :set_return_location
          retloc  = stack.pop
          fn_call = stack.peek
          fn_call.return_location = retloc
        when :set_retval
          retval  = stack.pop
          fn_call = stack.peek
          fn_call.return_value = retval
        when :set_arg
          value   = stack.pop
          fn_call = stack.peek
          index   = args[0]
          fn_call.arguments[index] = value
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
      fn_call = stack.peek
      fn      = fn_call.function
      env     = Env.new locals: {}, parent: fn.env
      [env, fn.beginning]
    end

    def swap_top
      first  = stack.pop
      second = stack.pop
      stack.push first
      stack.push second
    end
  end
end
