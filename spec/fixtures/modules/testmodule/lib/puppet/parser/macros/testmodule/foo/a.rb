# lib/puppet/parser/macros/testmodule/foo/a.rb
Puppet::Parser::Macros.newmacro 'testmodule::foo::a' do |a|
    (not a or a.equal?(:undef) or a.empty?) ? 'default a' : a
end
