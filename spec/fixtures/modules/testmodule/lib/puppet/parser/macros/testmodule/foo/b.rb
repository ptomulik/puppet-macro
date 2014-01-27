# lib/puppet/parser/macros/testmodule/foo/b.rb
Puppet::Parser::Macros.newmacro 'testmodule::foo::b' do |b, a|
    (not b or b.equal?(:undef) or b.empty?) ? "default b for a=#{a.inspect}" : b
end
