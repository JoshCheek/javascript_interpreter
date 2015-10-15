require 'rkelly'
require 'js_simulated_blocking/errors'
require 'js_simulated_blocking/callstack'
require 'js_simulated_blocking/ast_to_sexp'


class JsSimulatedBlocking
  def self.from_string(raw_js, stdout:)
    JsSimulatedBlocking.new sexp: parse(raw_js), stdout: stdout
  rescue RKelly::SyntaxError => err
    raise JsSimulatedBlocking::SyntaxError, err.message
  end

  private

  def self.parse(raw_js)
    parser = RKelly::Parser.new
    # RKelly raises for some errors, and for others just returns nil
    ast = parser.parse(raw_js) or
      raise RKelly::SyntaxError, "parser did not return an ast"
    AstToSexp.new.accept(ast)
  end

  public


  attr_accessor :stdout, :result, :callstack

  def initialize(sexp:, stdout:)
    self.stdout    = stdout
    self.result    = nil
    self.callstack = Callstack.new
    callstack.push sexp: sexp
  end

  def call
    # until callstack.finished?
    #   callstack.advance(self)
    # end
    sexp = callstack.head.sexp

    # require 'pp'; pp sexp
    self.result = interpret_expr sexp
    self
  end

  private

  def interpret_expr(expr)
    unless expr.first.kind_of? Symbol
      require "pry"
      binding.pry
    end

    type, *rest = expr
    case type
    when :true     then true
    when :false    then false
    when :null     then nil
    when :add      then rest.map { |child| interpret_expr child }.inject(:+)
    when :vars     then
      vars = rest.map { |name, value| [name, interpret_expr(value)] }.to_h
      callstack.declare vars
    when :elements then rest.inject(nil) { |_, child| interpret_expr child }
    when :number, :string then rest.first
    when :resolve  then callstack.resolve(rest.first)
    when :function then
      arguments, body = rest
      {type: :sexp, arguments: arguments, body: body}
    when :function_call then
      receiver_sexp, argument_sexps = rest
      function  = interpret_expr(receiver_sexp)
      arguments = argument_sexps.map { |arg| interpret_expr arg }
      locals    = function[:arguments].zip(arguments).to_h

      return_value = case function.fetch(:type)
      when :sexp then
        callstack.push(sexp: function.fetch(:body), locals: locals)
        interpret_expr function.fetch(:body)
      else raise "WHAT IS THIS?: #{function.fetch(:type).inspect}"
      end
      callstack.pop
      return_value

    when :return
      interpret_expr rest.first

    else
      print "\e[41;37m#{{type: type, rest: rest}.inspect}\e[0m\n"
      require "pry"
      binding.pry
    end
  end
end
