$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__),'..','..','..')))
require 'puppet/parser/macros'
module Puppet::Parser::Functions
  newfunction(:determine, :type => :rvalue, :doc => <<-EOT
  Determine value of a macro.

  This function ivokes a macro defined with `Puppet::Parser::Macros.newmacro`
  method and returns its value. The function takes macro name as first
  argument and macro parameters as the rest of arguments. The number of
  arguments provided by user is validated against the macro's arity.

  *Example*:

  Let say, you have defined the following macro in
  *puppet/parser/macros/sum.rb*:

      # puppet/parser/macros/sum.rb
      Puppet::Parser::Macros.newmacro 'sum' do |x,y|
        Integer(x) + Integer(y)
      end

  You may then invoke the macro from puppet as follows:

      $three = determine('sum',1,2) # -> 3
  EOT
  ) do |args|
    Puppet::Parser::Macros.call_macro_from_func(self,:determine,args)
  end
end
