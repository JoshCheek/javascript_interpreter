require 'rkelly'

parser = RKelly::Parser.new
ast    = parser.parse(
  "for(var i = 0; i < 10; i++) { var x = 5 + 5; }"
)

ast.each do |node|
  node.value  = 'hello' if node.value == 'i'
  node.name   = 'hello' if node.respond_to?(:name) && node.name == 'i'
end
puts ast.to_ecma # => nil

# >> for(var hello = 0; hello < 10; hello++) {
# >>   var x = 5 + 5;
# >> }
