# lib/puppet/parser/macros/sum2.rb
Puppet::Parser::Macros.newmacro 'sum2' do |x,y|
  Integer(x) + Integer(y)
end
