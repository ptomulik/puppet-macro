require 'spec_helper.rb'

testmod = File.expand_path(File.join(RSpec.configuration.module_path,'testmodule/lib'))
$LOAD_PATH.unshift(testmod) unless $LOAD_PATH.include?(testmod)
