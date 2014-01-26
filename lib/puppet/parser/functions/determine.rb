$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..','..')))
require 'puppet/parser/macros'
module Puppet::Parser::Functions
  newfunction(:determine, :type => :rvalue, :doc => <<-EOT
  EOT
  ) do |args|
    begin
      Puppet::Parser::Macros.call_macro(self,args)
    rescue Puppet::ParseError => err
      raise $!, "determine(): #{$!}", $!.backtrace
    end
  end
end
