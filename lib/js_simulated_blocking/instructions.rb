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
    instruction(:invoke)          { [:invoke] }
    instruction(:declare_var)     { [:declare_var] }
    instruction(:declare_arg)     { [:declare_arg] }
    instruction(:pop)             { [:pop] }
    instruction(:add)             { [:add] }
    instruction(:return)          { [:return] }
    instruction(:resolve)         { [:resolve] }
    instruction(:swap_top)        { [:swap_top] }
    instruction(:dot_access)      { [:dot_access] }

    instruction :begin_function do
      [:begin_function, -1]
    end

    instruction :end_function do |beginning_offset|
      instructions[beginning_offset][-1] = next_offset
      [:end_function]
    end
  end
end
