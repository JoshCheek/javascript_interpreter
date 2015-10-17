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

    def self.instruction(name, &body)
      define_method name do |*args|
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

    instruction(:push)              { |obj| [:push, obj] }
    instruction(:push_location)     { [:push_location] }
    instruction(:push_array)        { [:push_array] }
    instruction(:push_env)          { [:push_env] }
    instruction(:pop_env)           { [:pop_env] }
    instruction(:declare_var)       { [:declare_var] }
    instruction(:declare_arg)       { [:declare_arg] }
    instruction(:pop)               { [:pop] }
    instruction(:add)               { [:add] }
    instruction(:return)            { [:return] }
    instruction(:resolve)           { [:resolve] }
    instruction(:swap_top)          { [:swap_top] }
    instruction(:dot_access)        { [:dot_access] }
    instruction(:function_invoke)   { [:function_invoke] }
    instruction(:function_internal) { [:function_internal] }
    instruction(:new_object)        { [:new_object] }

    instruction :function_begin do |end_ofset|
      [:function_begin, end_ofset]
    end

    instruction :function_end do |beginning_offset|
      instructions[beginning_offset][-1] = next_offset
      [:function_end]
    end
  end
end
