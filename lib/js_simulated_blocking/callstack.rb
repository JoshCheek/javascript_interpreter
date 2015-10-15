class JsSimulatedBlocking
  class StackFrame
    attr_accessor :return_here, :sexp, :next_expr, :locals
    def initialize(return_here:, sexp:, next_expr:, locals:)
      self.sexp        = sexp
      self.locals      = locals
      self.next_expr   = next_expr
      self.return_here = return_here
    end

    def declare(vars)
      vars.each { |name, value| locals[name] = value }
    end

    def resolve(varname)
      locals.fetch(varname)
    end

    def all_locals
      return_here.all_locals.merge locals
    end
  end


  class NullStackFrame
    def sexp
      [:finished]
    end

    def all_locals
      {}
    end
  end


  class Callstack
    attr_accessor :head

    def initialize
      self.head = NullStackFrame.new
    end

    def push(sexp:, next_expr: 0, locals: {})
      self.head = StackFrame.new(
        sexp:        sexp,
        locals:      locals,
        next_expr:   next_expr,
        return_here: head,
      )
    end

    def pop
      self.head = self.head.return_here
    end

    def declare(vars)
      head.declare vars
    end

    def resolve(varname)
      head.resolve varname
    end

    def all_locals
      head.all_locals
    end
  end
end
