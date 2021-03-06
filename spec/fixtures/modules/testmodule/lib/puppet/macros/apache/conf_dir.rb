# lib/puppet/macros/apache/conf_dir.rb
Puppet::Macros.newmacro 'apache::conf_dir' do
  case os = lookupvar("::osfamily")
  when /FreeBSD/; '/usr/local/etc/apache22'
  when /Debian/; '/usr/etc/apache2'
  else
    raise Puppet::Error, "unsupported osfamily #{os.inspect}"
  end
end
