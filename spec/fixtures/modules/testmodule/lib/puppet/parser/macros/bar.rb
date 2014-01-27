Puppet::Parser::Macros.newmacro 'bar' do 
  Puppet::Parser::Macros.call_macro(self,'foo::bar',[])
end
