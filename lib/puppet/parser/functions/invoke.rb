$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..','..')))
require 'puppet/parser/macros'
module Puppet::Parser::Functions
  newfunction(:invoke, :type => :statement, :doc => <<-EOT
  EOT
  ) do |args|
    begin
      Puppet::Parser::Macros.call_macro(self,args)
    rescue Puppet::ParseError => err
      raise $!, "invoke(): #{$!}", $!.backtrace
    end
    nil
  end
end
