class JsSimulatedBlocking
  class Callstack
    def initialize
      @stack = []
    end

    def pop
      @stack.pop
    end

    def peek
      @stack.last
    end

    def push(obj)
      @stack.push obj
    end

    def inspect
      inspected     = "#<Callstack\n"
      index_width   = @stack.length.to_s.length
      indentation   = '  '
      padding       = indentation + ' '*index_width
      format        = "#{indentation}%#{index_width}d. %s"
      inspections   = @stack.reverse_each.with_index(1).map do |obj, index|
        first, *rest = obj.inspect.lines.map(&:chomp)
        [ sprintf(format, index, first),
          *rest.map { |line| "#{padding}#{line}" }
        ].join("\n")
      end
      inspected << inspections.join(",\n")
      inspected << "\n>\n"
    end
  end
end
