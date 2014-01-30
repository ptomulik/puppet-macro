Puppet::Macros.newmacro 'sum' do |*args|
  args.map{|x| Integer(x)}.reduce(0,:+)
end
