require 'js_simulated_blocking/functions'

class JsSimulatedBlocking
  class Instructions
    attr_accessor :instructions

    def initialize
      self.instructions = []
    end

    def to_a
      instructions
    end

    def empty?
      instructions.empty?
    end

    def setup
      if next_offset != InternalFunction::BEGINNING
        error_info = {next_offset: next_offset, expected: InternalFunction::BEGINNING}
        raise error_info.inspect
      end
      function_begin InternalFunction::BEGINNING
      function_internal

      if next_offset != InternalFunction::ENDING
        error_info = {next_offset: next_offset, expected: InternalFunction::ENDING}
        raise error_info.inspect
      end
      function_end InternalFunction::BEGINNING
      pop
    end

    find_unused = false
    $seen       = []
    $expected   = []
    at_exit {
      unseen = $expected - $seen.uniq
      puts "UNUSED INSTRUCTIONS: #{unseen.inspect}" if find_unused && unseen.any?
    }

    def self.instruction(name, &body)
      $expected << name
      define_method name do |*args|
        $seen << name
        instructions << instance_exec(*args, &body)
        self
      end
    end

    def current_offset
      next_offset - 1
    end

    def next_offset
      instructions.length
    end

    instruction(:push_fn_call) { [:push_fn_call] }
    instruction(:set_function) { [:set_function] }
    instruction(:set_retenv)   { [:set_retenv] }
    instruction(:pop_fn_call)  { [:pop_fn_call] }
    instruction(:set_retval)   { [:set_retval] }
    instruction(:set_arg)      { |index| [:set_arg, index] }
    instruction(:copy_this)    { [:copy_this] }

    $expected <<
    def set_return_location
      $seen << __method__
      push_retloc = [:push]
      instructions << push_retloc
      instructions << [:set_return_location]
      yield
      push_retloc << current_offset
    end

    instruction(:push)              { |obj|   [:push, obj] }
    instruction(:declare_arg)       { |index| [:declare_arg, index] }
    instruction(:push_env)          { [:push_env] }
    instruction(:declare_var)       { [:declare_var] }
    instruction(:pop)               { [:pop] }
    instruction(:add)               { [:add] }
    instruction(:return)            { [:return] }
    instruction(:resolve)           { [:resolve] }
    instruction(:swap_top)          { [:swap_top] }
    instruction(:dot_access)        { [:dot_access] }
    instruction(:function_invoke)   { [:function_invoke] }
    instruction(:function_internal) { [:function_internal] }
    instruction(:new_pre)           { [:new_pre]  }
    instruction(:new_post)          { [:new_post] }

    instruction :function_begin do |end_ofset|
      [:function_begin, end_ofset]
    end

    instruction :function_end do |beginning_offset|
      instructions[beginning_offset][-1] = next_offset
      [:function_end]
    end
  end
end
