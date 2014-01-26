$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..','..')))
require 'puppet/parser/macros'
module Puppet::Parser::Functions
  newfunction(:invoke, :type => :statement, :doc => <<-EOT
  Invoke macro as a statement.

  This function ivokes a macro defined with `Puppet::Parser::Macros.newmacro`
  method and returns nil (that is it doesn't return any value to puppet).
  The function takes macro name as first argument and macro parameters as the
  rest of arguments. The number of arguments provided by user is validated
  against the macro's arity.

  *Example*:

  Let say, you have defined the following macro in
  *puppet/parser/macros/print.rb*:

      # puppet/parser/macros/pring.rb
      Puppet::Parser::Macros.newmacro 'print' do |msg|
        print msg
      end

  You may then invoke the macro from puppet as follows:

      invoke('print',"hello world!\\n")
  EOT
  ) do |args|
    begin
      Puppet::Parser::Macros.call_macro(self,args)
    rescue Puppet::ParseError => err
      raise $!, "invoke(): #{$!}", $!.backtrace
    end
  end
end
