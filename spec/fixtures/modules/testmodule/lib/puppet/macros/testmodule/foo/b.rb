# lib/puppet/macros/testmodule/foo/b.rb
Puppet::Macros.newmacro 'testmodule::foo::b' do |b, a|
    pp2r(b) ? b : "default b for a=#{a.inspect}"
end
