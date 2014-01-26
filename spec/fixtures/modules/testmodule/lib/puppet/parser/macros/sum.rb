Puppet::Parser::Macros.newmacro 'sum', &lambda { |*args|
  args.map{|x| Integer(x)}.reduce(0,:+)
}
