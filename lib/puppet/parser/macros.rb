require 'puppet'
require 'puppet/util/autoload'

module Puppet::Parser::Macros; end

# Utility module for {Puppet::Parser::Macros}
module Puppet::Parser::Macros::DefaultEnvironment
  # This tries to ensure compatibility with different versions of Puppet
  # @api private
  if Puppet.respond_to?(:lookup)
    def default_environment
      Puppet.lookup(:current_environment)
    end
  else
    begin
      require 'puppet/context'
      def default_environment
        Puppet::Context.lookup(:current_environment)
      end
    rescue LoadError
      begin
        require 'puppet/node/environment'
        def default_environment
          Puppet::Node::Environment.current
        end
      rescue LoadError
        def default_environment
          nil
        end
      end
    end
  end
end

# Utility module for {Puppet::Parser::Macros}
module Puppet::Parser::Macros::Validation
  # Validate name
  #
  # @param name [Object] the name to be validated
  # @raise [ArgumentError]
  # @api private
  def validate_name(name, errclass = ArgumentError)
    unless valid_name?(name)
      raise errclass, "Invalid macro name #{name.inspect}"
    end
  end

  # @api private
  def macro_arities_by_parameters(macro)
    arg_kinds = macro.parameters.map{|kind,name| kind}
    [arg_kinds.count(:req), arg_kinds.include?(:rest) ? :inf : arg_kinds.size]
  end

  # @api private
  def macro_arities_by_arity(macro)
    arity = macro.arity
    (arity>=0) ? [arity, arity] : [arity.abs-1, :inf]
  end

  # @api private
  def macro_arities(macro)
    # Using macro.parameters is far more reliable than macro.arity, but
    # parameters are missing in ruby<=1.8.
    if macro.respond_to?(:parameters)
      macro_arities_by_parameters(macro)
    else
      macro_arities_by_arity(macro)
    end
  end

  # @api private
  def check_macro_arity(macro, macro_args, errclass = ArgumentError)
    min_arity, max_arity = macro_arities(macro)
    argn = macro_args.size
    if min_arity == max_arity
      if argn != min_arity
        raise errclass, "Wrong number of arguments (#{argn} for #{min_arity})"
      end
    elsif argn < min_arity
      raise errclass, "Wrong number of arguments (#{argn} for minimum #{min_arity})"
    elsif (not max_arity.equal?(:inf)) and (argn > max_arity)
      raise errclass, "Wrong number of arguments (#{argn} for maximum #{max_arity})"
    end
  end
end

module Puppet::Parser::Macros::ToLambda
  def to_lambda(block)
    if Puppet::Util::Package.versioncmp(RUBY_VERSION,"1.9") >=0 
      # This code is taken from: https://github.com/schneems/proc_to_lambda
      if RUBY_ENGINE && RUBY_ENGINE == "jruby"
        lambda(&block)
      else
        obj = Object.new
        obj.define_singleton_method(:_, &block)
        obj.method(:_).to_proc
      end
    else
      block
    end
  end
end

module Puppet::Parser::Macros
  # This object keeps track of macros defined within a single puppet
  # environment. Existing hashes (macros for existing environments) may be
  # retrieved with {macros} method.

  attr_accessor :environment

  class << self
    include DefaultEnvironment
    include Validation
    include ToLambda

    MACRO_NAME_RE =  /^[a-z_][a-z0-9_]*(?:::[a-z_][a-z0-9_]*)*$/

    # Check whether **name** is a valid macro name.
    #
    # @param name a name to be validated
    # @return [Boolean] `true` if the **name** is valid, or `false` otherwise
    # @api private
    def valid_name?(name)
      name.is_a?(String) and MACRO_NAME_RE.match(name)
    end

    # Define new preprocessor macro.
    #
    # A preprocessor macro is a callable object, which can be executed from
    # within a puppet manifest.
    #
    # **Example:**
    #
    #  Definition:
    #
    #  ```ruby
    #  # puppet/parser/macros/apache/package.rb
    #  Puppet::Parser.Macro.newmacro 'apache::package' do
    #    setcode do
    #      case os = fact(:osfamily)
    #      when 'FreeBSD'
    #        'www/apache22'
    #      when 'Debian'
    #        'apache2'
    #      else
    #        raise Puppet::Error, "#{os} is not supported"
    #      end
    #    end
    #  end
    #  ```
    #
    # Usage:
    #
    #  ```puppet
    #  # manifest.pp
    #  $package = determine('apache::package')
    #  ````
    #
    # @param name [String] macro name
    # @param options [Hash] additional options
    # @param block [Proc] macro definition
    #
    # @option options environment [Puppet::Node::Environment] an environment
    #   this macro belongs to, defautls to `default_environment`
    def newmacro(name,options={},&block)
      env = options[:environment] || default_environment
      Puppet.debug "overwritting macro #{name}" if macro(name,env,false)
      validate_name(name)
      macros(env)[name] = to_lambda(block)
    end

    # Get a hash of registered macros.
    #
    # @param env [Puppet::Node::Environment] puppet environment
    # @return [Hash] a hash with registered parser macros
    # @api private
    def macros(env = default_environment)
      @macros ||= {}
      @macros[env] ||= {}
    end

    # Retrieve single macro from {macros}
    #
    # @param name [String] macro name,
    # @param env [Puppet::Node::Environment] puppet environment,
    def macro(name, env = default_environment, auto = true)
      root = Puppet::Node::Environment.root
      macros(env)[name] || macros(root)[name] || (auto ? load(name,env) : nil)
    end

    # Accessor for singleton autoloader
    # @api private
    def autoloader
      unless @autoloader
        # Patched autoloader whith 'loadall' searching recursivelly
        @autoloader = Puppet::Util::Autoload.new(
          self, "puppet/parser/macros", :wrap => false
        )
        class << @autoloader
          def loadall
            self.class.loadall(File.join(@path,"**"))
          end
          def files_to_load
            self.class.files_to_load(File.join(@path,"**"))
          end
        end
      end
      @autoloader
    end

    # Load single macro from file
    #
    # @param name [String] macro name, e.g. `'foo::bar'`,
    # @param env [Puppet::Node::Environment] puppet environment,
    # @return [Macro|nil]
    # @api private
    def load(name, env = default_environment)
      # This block autoloads appropriate file each time a missing macro is
      # requested from hash.
      path = name.split('::').join('/')
      load_from_file(name, path, env)
    end

    # Load single file possibly containing macro definition.
    #
    # @param name [String] name of the macro to be loaded
    # @param path [String] path to macro file, relative to
    #   **puppet/parser/macros** and without `.rb` suffix,
    # @param env [Puppet::Node::Environment] puppet environment,
    # @return [Macro|nil]
    # @api private
    def load_from_file(name, path, env = default_environment)
      if autoloader.load(path, env)
        # the autoloaded code should add its macro to macros
        unless m = self.macro(name,env,false)
          Puppet.debug("#{autoloader.expand(path).inspect} loaded but it " +
            "didn't define macro #{name.inspect}")
        end
        m
      else
        Puppet.debug("could not autoload #{autoloader.expand(path).inspect}")
        nil
      end
    end

    # Autoload all existing macro definitions in current environment
    #
    # @param env [Puppet::Node::Environment] puppet environment,
    # @return [Array] an array of loaded files
    def loadall
      autoloader.loadall
    end

    # @api private
    def get_macro(name, env = default_environment, errclass = Puppet::Error)
      unless macro = self.macro(name,env)
        raise errclass, "Undefined macro #{name}"
      end
      macro
    end

    # Fix error messages to indicate number of arguments to parser function
    # instead of the number of arguments to macro and prepend the function
    # name.
    # @param func [Symbol|String] function name,
    # @param msg [String] original message from callee,
    # @param n [Integer] number of arguments shifted from function's arglist,
    # @return [String] fixed message
    # @api private
    def fix_error_msg(func, msg, n = 0)
      re = /^Wrong number of arguments \(([0-9]+) for (minimum |maximum )?([0-9]+)\)$/
      if m = re.match(msg)
        msg = "Wrong number of arguments (#{n+Integer(m.captures[0])} " +
          "for #{m.captures[1]}#{n+Integer(m.captures[2])})"
      end
      "#{func}(): #{msg}"
    end


    # Call a macro.
    #
    # @param scope [Puppet::Parser::Scope] scope of the calling function
    # @param name [String] name of the macro to be invoked
    # @param args [Array] arguments to be provided to teh macro
    # @param options [Hash] additional options
    # @param env [Puppet::Node::Environment] environment
    # @option options :a_err [Class] an exception to be raised when argument
    #   validation fails, defaults to **ArgumentError**
    # @option options :l_err [Class] an exception to be raised when macro
    #   lookup fails, defaults to **Puppet::Error**
    # @return the value of macro (result of evaluation)
    def call_macro(scope, name, args, options = {}, env = default_environment)
      validate_name(name, options[:a_err] || ArgumentError)
      macro = get_macro(name, env, options[:l_err] || Puppet::Error)
      check_macro_arity(macro, args, options[:a_err] || ArgumentError)
      scope.instance_exec(*args,&macro)
    end

    # Call a macro from parser function.
    #
    # This method is dedicated to be called from a parser function. It's used
    # by `determine` and `invoke`, but may be used by other custom functions as
    # well. This method checks the arguments and in case of validation error
    # raises Puppet::ParseError with appropriate message. If there is error
    # in number of arguments to macro, the exception message will reflect the
    # number of arguments to function, not the macro.
    #
    #
    # @param scope [Puppet::Parser::Scope] scope of the calling function
    # @param func_name [Symbol|String] name of the calling function
    # @param func_args [Array] arguments, as provided to calling function
    # @param n [Integer] number of extra arguments shifted from function's
    #   argument list
    # @param env [Puppet::Node::Environment] environment
    # @return the value of macro (result of evaluation)
    def call_macro_from_func(scope, func_name, func_args, n = 0, env = default_environment)
      begin
        if(func_args.size == 0)
          raise Puppet::ParseError, "Wrong number of arguments (0) - missing macro name"
        end
        options = { :a_err => Puppet::ParseError, :l_err => Puppet::ParseError }
        call_macro(scope, func_args[0], func_args[1..-1], options, env)
      rescue Puppet::ParseError => err
        msg = fix_error_msg(func_name, err.message, 1+n)
        raise Puppet::ParseError, msg, err.backtrace
      end
    end
  end
end

