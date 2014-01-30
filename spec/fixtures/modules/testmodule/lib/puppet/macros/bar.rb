Puppet::Macros.newmacro 'bar' do 
  call_macro('foo::bar',[])
end
