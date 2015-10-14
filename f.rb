require 'rkelly'

module Js
  class Function
    attr_accessor :fn_ast
    def initialize(fn_ast)
      @fn_ast = fn_ast
    end
  end

  class Interpreter
    include RKelly::Nodes
    attr_accessor :functions

    def initialize(ast)
      super()
      @ast = ast
      @functions = {}
    end

    def call
      eval_ast @ast
    end

    private

    def eval_ast(ast)
      case ast
      when SourceElementsNode      then ast.value.each { |child| eval_ast child }
      when FunctionDeclNode        then functions[ast.value] = Function.new(ast)
      when ExpressionStatementNode then eval_ast ast.value
      when FunctionCallNode        then
        require "pry"
        binding.pry
        # arguments = ast.arguments.
        functions[ast.value].call(arguments)
      else
        raise "Unhandled ast: #{ast.inspect}" # ~> RuntimeError: Unhandled ast: #<RKelly::Nodes::FunctionCallNode:0x007ff4fca2eda8 @value=#<RKelly::Nodes::ResolveNode:0x007ff4fca35c98 @value="setTimeout", @comments=[], @range=<{line:7 char:3 (172)}...{line:7 char:12 (181)}>, @filename=nil>, @comments=[], @range=<{line:7 char:3 (172)}...{line:7 char:86 (255)}>, @filename=nil, @arguments=#<RKelly::Nodes::ArgumentsNode:0x007ff4fca2ef10 @value...
      end
    end
  end
end


ast = RKelly.parse(<<-JAVASCRIPT)
  function minutesSeconds() {
    var now = new Date();
    return "" + now.getMinutes() + ":" + now.getSeconds();
  }

  // this one is async b/c it provides a callback
  setTimeout((function(){ console.log("First Defined: " + minutesSeconds()); }), 2000);

  // this one saves the current callstack as the callback
  setTimeout(null, 1000);
  console.log("Second Defined: " + minutesSeconds());

  // this one is async b/c it provides a callback
  setTimeout(function(){ console.log("Third Defined: " + minutesSeconds()) }, 2000);
JAVASCRIPT

Js::Interpreter.new(ast).call

# ~> RuntimeError
# ~> Unhandled ast: #<RKelly::Nodes::FunctionCallNode:0x007ff4fca2eda8 @value=#<RKelly::Nodes::ResolveNode:0x007ff4fca35c98 @value="setTimeout", @comments=[], @range=<{line:7 char:3 (172)}...{line:7 char:12 (181)}>, @filename=nil>, @comments=[], @range=<{line:7 char:3 (172)}...{line:7 char:86 (255)}>, @filename=nil, @arguments=#<RKelly::Nodes::ArgumentsNode:0x007ff4fca2ef10 @value=[#<RKelly::No...
# ~>
# ~> /var/folders/7g/mbft22555w3_2nqs_h1kbglw0000gn/T/seeing_is_believing_temp_dir20151003-58068-1fc18z4/program.rb:36:in `eval_ast'
# ~> /var/folders/7g/mbft22555w3_2nqs_h1kbglw0000gn/T/seeing_is_believing_temp_dir20151003-58068-1fc18z4/program.rb:34:in `eval_ast'
# ~> /var/folders/7g/mbft22555w3_2nqs_h1kbglw0000gn/T/seeing_is_believing_temp_dir20151003-58068-1fc18z4/program.rb:30:in `block in eval_ast'
# ~> /var/folders/7g/mbft22555w3_2nqs_h1kbglw0000gn/T/seeing_is_believing_temp_dir20151003-58068-1fc18z4/program.rb:30:in `each'
# ~> /var/folders/7g/mbft22555w3_2nqs_h1kbglw0000gn/T/seeing_is_believing_temp_dir20151003-58068-1fc18z4/program.rb:30:in `eval_ast'
# ~> /var/folders/7g/mbft22555w3_2nqs_h1kbglw0000gn/T/seeing_is_believing_temp_dir20151003-58068-1fc18z4/program.rb:22:in `call'
# ~> /var/folders/7g/mbft22555w3_2nqs_h1kbglw0000gn/T/seeing_is_believing_temp_dir20151003-58068-1fc18z4/program.rb:60:in `<main>'
