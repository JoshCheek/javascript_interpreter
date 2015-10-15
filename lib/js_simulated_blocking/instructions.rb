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
      begin_function InternalFunction::BEGINNING
      invoke_internal

      if next_offset != InternalFunction::ENDING
        error_info = {next_offset: next_offset, expected: InternalFunction::ENDING}
        raise error_info.inspect
      end
      end_function InternalFunction::BEGINNING
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

    instruction(:push)            { |obj| [:push, obj] }
    instruction(:push_location)   { [:push_location] }
    instruction(:push_array)      { [:push_array] }
    instruction(:push_env)        { [:push_env] }
    instruction(:pop_env)         { [:pop_env] }
    instruction(:declare_var)     { [:declare_var] }
    instruction(:declare_arg)     { [:declare_arg] }
    instruction(:pop)             { [:pop] }
    instruction(:add)             { [:add] }
    instruction(:return)          { [:return] }
    instruction(:resolve)         { [:resolve] }
    instruction(:swap_top)        { [:swap_top] }
    instruction(:dot_access)      { [:dot_access] }
    instruction(:invoke)          { [:invoke] }
    instruction(:invoke_internal) { [:invoke_internal] }

    instruction :begin_function do |end_ofset|
      [:begin_function, end_ofset]
    end

    instruction :end_function do |beginning_offset|
      instructions[beginning_offset][-1] = next_offset
      [:end_function]
    end
  end
end
