# lib/puppet/parser/macros/sum2.rb
Puppet::Parser::Macros.newmacro 'sum2', &lambda { |x,y|
  Integer(x) + Integer(y)
}
