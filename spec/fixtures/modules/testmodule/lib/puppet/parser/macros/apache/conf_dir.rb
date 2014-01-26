# lib/puppet/parser/macros/apache/conf_dir.rb
Puppet::Parser::Macros.newmacro 'apache::conf_dir', &lambda {
  case os = lookupvar("::osfamily")
  when /FreeBSD/; '/usr/local/etc/apache22'
  when /Debian/; '/usr/etc/apache2'
  else
    raise Puppet::Error, "unsupported osfamily #{os.inspect}"
  end
}
