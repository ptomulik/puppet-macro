# lib/puppet/macros/sum2.rb
Puppet::Macros.newmacro 'sum2' do |x,y|
  Integer(x) + Integer(y)
end
