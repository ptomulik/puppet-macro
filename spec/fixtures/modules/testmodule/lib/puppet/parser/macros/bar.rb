Puppet::Parser::Macros.newmacro 'bar', &lambda {
  function_determine(['foo::bar'])
}
