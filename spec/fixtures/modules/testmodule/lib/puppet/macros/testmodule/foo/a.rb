# lib/puppet/macros/testmodule/foo/a.rb
Puppet::Macros.newmacro 'testmodule::foo::a' do |a|
    pp2r(a) ? a : 'default a'
end
