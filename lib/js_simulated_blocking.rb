require 'rkelly'
require 'js_simulated_blocking/errors'

# Subclasses this https://github.com/nene/rkelly-remix/blob/5034089bc821d61dbcb3472894177a293f1755a8/lib/rkelly/visitors/visitor.rb
class AstVisitor < RKelly::Visitors::Visitor
  # ALL_NODES = %w{ For ForIn Try BracketAccessor DotAccessor } +
  #   TERMINAL_NODES + SINGLE_VALUE_NODES + BINARY_NODES + ARRAY_VALUE_NODES +
  #   NAME_VALUE_NODES + PREFIX_POSTFIX_NODES + CONDITIONAL_NODES +
  #   FUNC_CALL_NODES + FUNC_DECL_NODES

  # list of nodes I've looked at and like how they work
  OK_NODES          = %w[ExpressionStatement]
  REWRITTEN_NODES   = %w[Add True False Null Number SourceElements]
  UNEVALUATED_NODES = ALL_NODES - OK_NODES

  UNEVALUATED_NODES.each do |type|
    define_method "visit_#{type}Node" do |node|
      inspected = {type: type, node: node}.inspect
      raise inspected
    end
  end

  def visit_TrueNode(*)  [:true]  end
  def visit_FalseNode(*) [:false] end
  def visit_NullNode(*)  [:null]  end

  def visit_SourceElementsNode(*) [:elements, *super] end
  def visit_AddNode(o)            [:add,      *super] end

  def visit_StringNode(node) [:string, node.value[1...-1]] end # shitty escaping >.<
  def visit_NumberNode(node) [:number, node.value.to_f]    end

  meths = instance_methods
  REWRITTEN_NODES.each do |type|
    meths.include?(:"visit_#{type}Node") || raise("NOT REWRITTEN: #{type.inspect}")
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
    self.callstack = []
    self.result    = nil
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
    when :elements then rest.inject(nil) { |_, child| interpret_sexp child }
    when :true     then true
    when :false    then false
    when :null     then nil
    when :add      then rest.map { |child| interpret_sexp child }.inject(:+)
    when :number, :string  then rest.first
    # when :expression then rest.inject(nil) { |_, child| interpret_sexp child }
    else
      print "\e[41;37m#{{type: type, rest: rest}.inspect}\e[0m\n"
      require "pry"
      binding.pry
    end
  end
end
