require 'rkelly'
require 'js_simulated_blocking/errors'

# Subclasses this https://github.com/nene/rkelly-remix/blob/5034089bc821d61dbcb3472894177a293f1755a8/lib/rkelly/visitors/visitor.rb
# TODO: Rename to AstToSexp
class AstVisitor < RKelly::Visitors::Visitor
  # ALL_NODES = %w{ For ForIn Try BracketAccessor DotAccessor } +
  #   TERMINAL_NODES + SINGLE_VALUE_NODES + BINARY_NODES + ARRAY_VALUE_NODES +
  #   NAME_VALUE_NODES + PREFIX_POSTFIX_NODES + CONDITIONAL_NODES +
  #   FUNC_CALL_NODES + FUNC_DECL_NODES

  # list of nodes I've looked at and like how they work
  ALL_NODES.each do |type|
    define_method "visit_#{type}Node" do |node|
      inspected = {type: type, node: node.to_sexp}.inspect
      raise inspected
    end
  end

  def visit_VarStatementNode(node)
    declarations = node.value.map do |decl|
      decl.constant? and raise "Haven't checked this out yet: #{decl.to_sexp.inspect}"
      sexp       = [decl.name.to_s.intern]
      assignment = decl.value
      sexp << assignment.value.accept(self) if assignment
      sexp
    end
    [:vars, *declarations]
  end

  def visit_FunctionExprNode(node)
    body = node.function_body.value.accept(self)
    args = node.arguments.map(&:value).map(&:intern)
    [:function, args, body]
  end

  def visit_FunctionCallNode(node)
    receiver  = node.value.accept(self)
    arguments = node.arguments.value.map { |arg| arg.accept self }
    [:function_call, receiver, arguments]
  end

  def visit_TrueNode(*)  [:true]  end
  def visit_FalseNode(*) [:false] end
  def visit_NullNode(*)  [:null]  end

  def visit_StringNode(node)  [:string,  node.value[1...-1]] end # shitty escaping >.<
  def visit_NumberNode(node)  [:number,  node.value.to_f]    end
  def visit_ResolveNode(node) [:resolve, node.value.intern]  end

  def visit_ParentheticalNode(*)       super end
  def visit_ExpressionStatementNode(*) super end

  def visit_ReturnNode(*)         [:return,    super] end
  def visit_AddNode(o)            [:add,      *super] end
  def visit_SourceElementsNode(*) [:elements, *super] end
end


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



class JsSimulatedBlocking
  def self.from_string(raw_js, stdout:)
    parser = RKelly::Parser.new
    # RKelly raises for some errors, and for others just returns nil
    ast = parser.parse(raw_js) or
      raise RKelly::SyntaxError, "parser did not return an ast"
    JsSimulatedBlocking.new ast: ast, stdout: stdout
  rescue RKelly::SyntaxError => err
    raise JsSimulatedBlocking::SyntaxError, err.message
  end


  attr_accessor :ast, :stdout, :result, :callstack

  def initialize(ast:, stdout:)
    self.ast       = ast
    self.stdout    = stdout
    self.result    = nil
    self.callstack = Callstack.new
    callstack.push sexp: AstVisitor.new.accept(ast)
  end

  def call
    sexp = AstVisitor.new.accept(ast)
    # require 'pp'; pp sexp
    self.result = interpret_sexp sexp
    self
  end

  private

  def interpret_sexp(sexp)
    unless sexp.first.kind_of? Symbol
      require "pry"
      binding.pry
    end

    type, *rest = sexp
    case type
    when :true     then true
    when :false    then false
    when :null     then nil
    when :add      then rest.map { |child| interpret_sexp child }.inject(:+)
    when :vars     then
      vars = rest.map { |name, value| [name, interpret_sexp(value)] }.to_h
      callstack.declare vars
    when :elements then rest.inject(nil) { |_, child| interpret_sexp child }
    when :number, :string then rest.first
    when :resolve  then callstack.resolve(rest.first)
    when :function then
      arguments, body = rest
      {type: :sexp, arguments: arguments, body: body}
    when :function_call then
      receiver_sexp, argument_sexps = rest
      function  = interpret_sexp(receiver_sexp)
      arguments = argument_sexps.map { |arg| interpret_sexp arg }
      locals    = function[:arguments].zip(arguments).to_h

      return_value = case function.fetch(:type)
      when :sexp then
        callstack.push(sexp: function.fetch(:body), locals: locals)
        interpret_sexp function.fetch(:body)
      else raise "WHAT IS THIS?: #{function.fetch(:type).inspect}"
      end
      callstack.pop
      return_value

    when :return
      interpret_sexp rest.first

    else
      print "\e[41;37m#{{type: type, rest: rest}.inspect}\e[0m\n"
      require "pry"
      binding.pry
    end
  end
end
