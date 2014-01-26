# lib/puppet/parser/macros/puppet/config/content.rb
Puppet::Parser::Macros.newmacro 'puppet::config::content', &lambda {|*args|
  if args.size > 1
    raise Puppet::ParseError, "Wrong number of arguments (#{args.size+1} for maximum 2)"
  end
  args << '/etc/puppet/puppet.conf' if args.size < 1
  File.read(args[0])
}
