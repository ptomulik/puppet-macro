require 'spec_helper.rb'

RSpec.configuration.module_path.split(File::PATH_SEPARATOR).each do |mp|
  testmod = File.expand_path(File.join(mp,'testmodule','lib'))
  if testmod =~ /#{Regexp.escape(File.join('spec','fixtures','modules'))}/
    $LOAD_PATH.unshift(testmod) unless $LOAD_PATH.include?(testmod)
  end
end
