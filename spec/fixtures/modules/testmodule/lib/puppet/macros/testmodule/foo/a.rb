# lib/puppet/macros/testmodule/foo/a.rb
Puppet::Macros.newmacro 'testmodule::foo::a' do |a|
    (not a or a.equal?(:undef) or a.empty?) ? 'default a' : a
end
