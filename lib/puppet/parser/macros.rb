require 'puppet/util/autoload'

module Puppet::Parser::Macros
  # This object keeps track of macros defined within a single puppet
  # environment. Existing hashes (macros for existing environments) may be
  # retrieved with {macros} method.

  attr_accessor :environment

  class << self
    MACRO_NAME_RE =  /^[a-z_][a-z0-9_]*(?:::[a-z_][a-z0-9_]*)*$/

    # Check whether **name** is a valid macro name.
    #
    # @param name a name to be validated
    # @return [Boolean] `true` if the **name** is valid, or `false` otherwise
    # @api private
    def valid_name?(name)
      name.is_a?(String) and MACRO_NAME_RE.match(name)
    end

    # Validate name
    #
    # @param name [Object] the name to be validated
    # @raise [ArgumentError]
    # @api private
    def validate_name(name)
      unless valid_name?(name)
        raise ArgumentError, "Invalid macro name #{name.inspect}"
      end
    end

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
    #   this macro belongs to, defautls to {default_environment}
    def newmacro(name,options={},&block)
      env = options[:environment] || default_environment
      Puppet.debug "overwritting macro #{name}" if macro(name,env,false)
      validate_name(name)
      macros(env)[name] = block
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
        if m = self.macro(name,env,false)
          return m
        else
          msg = "#{autoloader.expand(path).inspect} loaded but it didn't " +
            "define macro #{name.inspect}"
        end
      else
        msg = "could not autoload #{autoloader.expand(path).inspect}"
      end
      Puppet.debug(msg)
      nil
    end

    # Autoload all existing macro definitions in current environment
    #
    # @param env [Puppet::Node::Environment] puppet environment,
    # @return [Array] an array of loaded files
    def loadall
      autoloader.loadall
    end

    # @api private
    def macro_arities(macro)
      # Using macro.parameters is far more reliable than macro.arity. The
      # parameters, however, were introduced in ruby 1.9.
      if macro.respond_to?(:parameters)
        arg_kinds = macro.parameters.map{|kind,name| kind}
        min_arity = arg_kinds.count(:req)
        max_arity = arg_kinds.include?(:rest) ? :inf : arg_kinds.size
      else
        arity = macro.arity
        min_arity, max_arity = (arity>=0) ? [arity, arity] : [arity.abs-1, :inf]
      end
      [min_arity,max_arity]
    end

    # @api private
    def check_macro_arity(macro,macro_args)
      min_arity, max_arity = macro_arities(macro)
      argn = macro_args.size
      if min_arity == max_arity
        if argn != min_arity
          raise Puppet::ParseError,
            "Wrong number of arguments (#{1+argn} for #{1+min_arity})"
        end
      elsif argn < min_arity
        raise Puppet::ParseError,
          "Wrong number of arguments (#{1+argn} for minimum #{1+min_arity})"
      elsif (not max_arity.equal?(:inf)) and (argn > max_arity)
        raise Puppet::ParseError,
          "Wrong number of arguments (#{1+argn} for maximum #{1+max_arity})"
      end
    end

    # Call the macro from a parser function.
    #
    # @param scope [Puppet::Parser::Scope] scope of the calling function
    # @param func_args [Array] arguments, as provided to calling function
    # @param env [Puppet::Node::Environment] environment
    def call_macro(scope,func_args,env = default_environment)
      if(func_args.size == 0)
        raise Puppet::ParseError, "Wrong number of arguments (0). You " +
          "must provide at least macro name"
      end

      macro_name = func_args[0]
      begin
        validate_name(macro_name)
      rescue ArgumentError => err
        raise Puppet::ParseError, "#{err.message}"
      end

      unless macro = self.macro(macro_name,env)
        raise Puppet::ParseError, "Undefined macro #{macro_name}"
      end

      macro_args = func_args[1..-1]
      check_macro_arity(macro,macro_args)
      scope.instance_exec(*macro_args,&macro)
    end
  end
end

