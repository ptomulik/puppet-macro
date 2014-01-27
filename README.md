#ptomulik-macro

[![Build Status](https://travis-ci.org/ptomulik/puppet-macro.png?branch=master)](https://travis-ci.org/ptomulik/puppet-macro)
[![Coverage Status](https://coveralls.io/repos/ptomulik/puppet-macro/badge.png)](https://coveralls.io/r/ptomulik/puppet-macro)
[![Code Climate](https://codeclimate.com/github/ptomulik/puppet-macro.png)](https://codeclimate.com/github/ptomulik/puppet-macro)

####<a id="table-of-contents"></a>Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Usage](#usage)
   * [Example 1: Defining macro in ruby code](#example-1-defining-macro-in-ruby-code)
   * [Example 2: Invoking macro in puppet manifest](#example-2-invoking-macro-in-puppet-manifest)
   * [Example 3: Macro with parameters](#example-3-macro-with-parameters)
   * [Example 4: Variable number of parameters](#example-4-variable-number-of-parameters)
   * [Example 5: Default parameters](#example-5-default-parameters)
   * [Example 6: Invoking macro from macro](#example-6-invoking-macro-from-macro)
   * [Example 7: Using variables](#example-7-using-variables)
   * [Example 8: Building dependencies between parameters](#example-8-building-dependencies-between-parameters)
4. [Reference](#reference)
   * [Function Reference](#function-reference)
   * [API Reference](#api-reference)
5. [Limitations](#limitations)

##<a id="overview"></a>Overview

Puppet parser macros.

[[Table of Contents](#table-of-contents)]

##<a id="module-description"></a>Module Description

With this functionality module developers may define named macros and evaluate
them in manifests. This works similarly to parser
[functions](http://docs.puppetlabs.com/guides/custom_functions.html) but
implementing a macro is a little bit easier. Also, macros may use
"hierarchical" names in `foo::bar::geez` form, so a module developer may easily
establish one-to-one correspondence between macro names and class/define
parameters.

The main reason for this module being developed is exemplified in
[Example 8](#example-8-building-dependencies-between-parameters).

[[Table of Contents](#table-of-contents)]

##<a id="usage"></a>Usage

###<a id="example-1-defining-macro-in-ruby-code"></a>Example 1: Defining macro in ruby code

To define a macro named **foo::bar** in a module write a file
named *lib/puppet/parser/macros/foo/bar.rb*:

```ruby
# lib/puppet/parser/macros/foo/bar.rb
Puppet::Parser::Macros.newmacro 'foo::bar' do
  'macro foo::bar'
end
```

The above macro simply returns the `'macro foo::bar'` string.

[[Table of Contents](#table-of-contents)]

###<a id="example-2-invoking-macro-in-puppet-manifest"></a>Example 2: Invoking macro in puppet manifest

Nothing simpler than:

```puppet
$foo_bar = determine('foo::bar')
notify { foo_bar: message => "determine('foo::bar') -> ${foo_bar}" }
```

If you don't need the value returned by macro, then you may invoke macro as
a statement:

```puppet
invoke('foo::bar')
```

[[Table of Contents](#table-of-contents)]

###<a id="example-3-macro-with-parameters"></a>Example 3: Macro with parameters

Let's define macro `sum2` which adds two integers:

```ruby
# lib/puppet/parser/macros/sum2.rb
Puppet::Parser::Macros.newmacro 'sum2' do |x,y|
  Integer(x) + Integer(y)
end
```

Now `sum2` may be used as follows:

```puppet
$sum = determine('sum2', 1, 2)
notify { sum: message => "determine('sum2',1,2) -> ${sum}" }
```

[[Table of Contents](#table-of-contents)]

###<a id="example-4-variable-number-of-parameters"></a>Example 4: Variable number of parameters

Let's redefine macro from [Example 3](#example-3-macro-with-parameters) to
accept arbitrary number of parameters:

```ruby
# lib/puppet/parser/macros/sum.rb
Puppet::Parser::Macros.newmacro 'sum' do |*args|
  args.map{|x| Integer(x)}.reduce(0,:+)
end
```

Now, few experiments:

```puppet
$zero = determine('sum')
$one = determine('sum',1)
$three = determine('sum',1,2)
notify { zero: message => "determine('sum') -> ${zero}" }
notify { one: message => "determine('sum',1) -> ${one}" }
notify { three: message => "determine('sum',1,2) -> ${three}" }
```

[[Table of Contents](#table-of-contents)]

###<a id="example-5-default-parameters"></a>Example 5: Default parameters

Default parameters work only with ruby **1.9+**. If you don't care about
compatibility with ruby **1.8**, you may define a macro with default parameters
in the usual way:

```ruby
# lib/puppet/parser/macros/puppet/config/content.rb
Puppet::Parser::Macros.newmacro 'puppet::config::content' do |file='/etc/puppet/puppet.conf'|
  File.read(file)
end
```

Now you may use it with:

```puppet
$content = determine('puppet::config::content')
notify { content: message => $content }
```

or

```puppet
$content = determine('puppet::config::content','/usr/local/etc/puppet/puppet.conf')
notify { content: message => $content }
```

If you need the same for ruby *1.8*, here is a workaround (note that the
caller i.e the [determine](#determine) function, will check the minimum arity,
so we only check the maximum):

```ruby
# lib/puppet/parser/macros/puppet/config/content.rb
Puppet::Parser::Macros.newmacro 'puppet::config::content' do |*args|
  if args.size > 1
    raise Puppet::ParseError, "Wrong number of arguments (#{args.size} for maximum 1)"
  end
  args << '/etc/puppet/puppet.conf' if args.size < 1
  File.read(args[0])
end
```

[[Table of Contents](#table-of-contents)]

###<a id="example-6-invoking-macro-from-macro"></a>Example 6: Invoking macro from macro

```ruby
# lib/puppet/parser/macros/bar.rb
Puppet::Parser::Macros.newmacro 'bar' do
  function_determine(['foo::bar'])
end
```

then in puppet

```puppet
$bar = determine('bar')
notify { bar: message => "determine('bar') -> ${bar}" }
```

The above puppet code would print

```console
Notice: determine('bar') -> macro foo::bar
```

that is the result of macro `foo::bar` defined in
[Example 1](#example-1-defining-macro-in-ruby-code).

[[Table of Contents](#table-of-contents)]

###<a id="example-7-using-variables"></a>Example 7: Using variables

You may access puppet variables, for example `$::osfamily` (fact).  The
following example determines default location of apache configs for operating
system running on slave:

```ruby
# lib/puppet/parser/macros/apache/conf_dir.rb
Puppet::Parser::Macros.newmacro 'apache::conf_dir' do
  case os = lookupvar("::osfamily")
  when /FreeBSD/; '/usr/local/etc/apache22'
  when /Debian/; '/usr/etc/apache2'
  else
    raise Puppet::Error, "unsupported osfamily #{os.inspect}"
  end
end
```

```puppet
$apache_conf_dir = determine('apache::conf_dir')
notify { apache_conf_dir: message => "determine('apache::conf_dir') -> ${apache_conf_dir}" }
```

[[Table of Contents](#table-of-contents)]

###<a id="example-8-building-dependencies-between-parameters"></a>Example 8: Building dependencies between parameters

Macros may be used to inter-depend parameters of defined types or classes. In
other words, if one parameter is altered by user, others should be adjusted
automatically, unless user specify them explicitly. For example, we may have a
defined type `testmodule::foo` with two parameters `$a` and `$b` and we want
`$b` to depend on `$a`.  So, we may define macros `testmodule::foo::a` and
`testmodule::foo::b`, and `testmodule::foo::b` may accept `$a` as an argument:

```ruby
# lib/puppet/parser/macros/testmodule/foo/a.rb
Puppet::Parser::Macros.newmacro 'testmodule::foo::a' do |a|
    (not a or a.equal?(:undef) or a.empty?) ? 'default a' : a
end
```

```ruby
# lib/puppet/parser/macros/testmodule/foo/b.rb
Puppet::Parser::Macros.newmacro 'testmodule::foo::b' do |b, a|
    (not b or b.equal?(:undef) or b.empty?) ? "default b for a=#{a.inspect}" : b
end
```

Then, if we split `testmodule::foo` into actual implementation (let say
`testmodule::foo_impl`) and a wrapper (let's call it simply `testmodule::foo`),
the job may be finished as follows:

```puppet
# manifests/impl/foo.pp
define testmodule::impl::foo($a, $b) {
  notify{$title: message => "${title}: a=\'${a}\', b=\'${b}\'"}
}
```

```puppet
# manifests/foo.pp
define testmodule::foo($a = undef, $b = undef)
{
  $_a = determine('testmodule::foo::a', $a)
  $_b = determine('testmodule::foo::b', $b, $_a)
  testmodule::impl::foo{"$title":
    a => $_a,
    b => $_b
  }
}
```

Now, the following manifest

```console
puppet apply --modulepath $(pwd) <<!
testmodule::foo {defaults: }
testmodule::foo {custom_a: a => 'custom a' }
testmodule::foo {custom_b: b => 'custom b' }
testmodule::foo {custom_a_and_b: a => 'custom a', b => 'custom b' }
testmodule::foo {other: }
Testmodule::Foo[other] { a => 'other default a' }
!
```

would output these lines:

```console
Notice: defaults: a='default a', b='default b for a="default a"'
Notice: custom_a: a='custom a', b='default b for a="custom a"'
Notice: custom_b: a='default a', b='custom b'
Notice: custom_a_and_b: a='custom a', b='custom b'
Notice: other: a='other default a', b='default b for a="other default a"'
```

[[Table of Contents](#table-of-contents)]

##<a id="reference"></a>Reference

###<a id="function-reference"></a>Function reference

####<a id="index-of-functions"></a>Index of functions:

* [determine](#determine)
* [invoke](#invoke)

####<a id="determine"></a>determine
Determine value of a macro.

This function ivokes a macro defined with `Puppet::Parser::Macros.newmacro`
method and returns its value. The function takes macro name as first
argument and macro parameters as the rest of arguments. The number of
arguments provided by user is validated against macro's arity.

*Example*:

Let say, you have defined the following macro in
*puppet/parser/macros/sum.rb*:

    # puppet/parser/macros/sum.rb
    Puppet::Parser::Macros.newmacro 'sum' do |x,y|
      Integer(x) + Integer(y)
    end

You may then invoke the macro from puppet as follows:

    $three = determine('sum',1,2) # -> 3

- *Type*: rvalue

[[Index of functions](#index-of-functions)|[Table of Contents](#table-of-contents)]

####<a id="invoke"></a>invoke
Invoke macro as a statement.

This function ivokes a macro defined with `Puppet::Parser::Macros.newmacro`
method. The function takes macro name as first argument and macro parameters
as the rest of arguments. The number of arguments provided by user is
validated against macro's arity.

*Example*:

Let say, you have defined the following macro in
*puppet/parser/macros/print.rb*:

    # puppet/parser/macros/pring.rb
    Puppet::Parser::Macros.newmacro 'print' do |msg|
      print msg
    end

You may then invoke the macro from puppet as follows:

    invoke('print',"hello world!\\n")

- *Type*: statement

[[Index of functions](#index-of-functions)|[Table of Contents](#table-of-contents)]

###<a id="api-reference"></a>API Reference

API reference may be generated with

```console
bundle exec rake yard
```

The generated documentation goes to `doc/` directory. Note that this works only
under ruby >= 1.9.

[[Table of Contents](#table-of-contents)]

##Limitations

* Currently there is no possibility to define macro in puppet manifests, that is
  we only can define macro using ruby and use it in ruby or puppet. I believe
  this functionality may implemented as an additional parser function (call it
  `macro`) and it should work with the help of puppet lambdas, which are
  available in future parser.
* Currently there is no way to store and auto-generate documentation for macros.
  It should work similarly as for functions but its not implemented at the
  moment. This may be added in future versions.

[[Table of Contents](#table-of-contents)]
