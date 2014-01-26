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

|[Table of Contents](#table-of-contents)|

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

|[Table of Contents](#table-of-contents)|

##<a id="usage"></a>Usage

###<a id="example-1-defining-macro-in-ruby-code"></a>Example 1: Defining macro in ruby code

To define a macro named **foo::bar** in a module **mymodule** write a file
named *mymodule/lib/puppet/parser/macros/foo/bar.rb*:

```ruby
# mymodule/lib/puppet/parser/macros/foo/bar.rb
Puppet::Parser::Macros.newmacro 'foo::bar' do
  'macro foo::bar'
end
```

The above macro simply returns the `'macro foo::bar'` string.

|[Table of Contents](#table-of-contents)|

###<a id="example-2-invoking-macro-in-puppet-manifest"></a>Example 2: invoking macro in puppet-manifest

Nothing simpler that:

```puppet
$foo_bar = determine('foo::bar')
notify { foo_bar: message => "determine('foo::bar') -> ${foo_bar}" }
```

If you don't need the value returned by macro, then the you may invoke macro as
a statement:

```puppet
invoke('foo::bar')
```

|[Table of Contents](#table-of-contents)|

###<a id="example-3-macro-with-parameters"></a>Example 3: macro with parameters

Let's define macro `sum` which adds two integers:

```ruby
# mymodule/lib/puppet/parser/macros/sum.rb
Puppet::Parser::Macros.newmacro 'sum' do |x,y|
  Integer(x) + Integer(y)
end
```

Now you may use it with:

```puppet
$sum = determine('sum', 1, 2)
notify { sum: message => "determine('sum',1,2) -> ${sum}" }
```

|[Table of Contents](#table-of-contents)|

###<a id="example-4-variable-number-of-parameters"></a>Example 4: Variable number of parameters

Let's redefine our `sum` from [Example 3](#example-3-macro-with-parameters) to accept arbitrary number of parameters:

```ruby
# mymodule/lib/puppet/parser/macros/sum.rb
Puppet::Parser::Macros.newmacro 'sum' do |*args|
  args.map{|x| Integer(x)}.reduce(0,:+)
end
```

Now you may use it with:

```puppet
$zero = determine('sum')
$one = determine('sum',1)
$three = determine('sum',1,2)
notify { zero: message => "determine('sum') -> ${zero}" }
notify { one: message => "determine('sum',1) -> ${one}" }
notify { three: message => "determine('sum',1,2) -> ${three}" }
```

|[Table of Contents](#table-of-contents)|

###<a id="example-5-default-parameters"></a>Example 5: Default parameters

Default parameters work only with ruby **1.9+**. If you don't care about
compatibility with ruby **1.8**, you may define a macro with default parameters
in the usual way:
```ruby
# mymodule/lib/puppet/parser/macros/puppet/config/content.rb
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

|[Table of Contents](#table-of-contents)|

###<a id="example-6-invoking-macro-from-macro"></a>Example 6: Invoking macro from macro

```ruby
# mymodule/lib/puppet/parser/macros/bar.rb
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

|[Table of Contents](#table-of-contents)|

###<a id="example-7-using-variables"></a>Example 7: Using variables

You may access puppet variables, for example `$::osfamily` fact.  The following
example determines default location of apache configs for operating system
running on slave:

```ruby
# mymodule/lib/puppet/parser/macros/apache/conf_dir.rb
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

|[Table of Contents](#table-of-contents)|

###<a id="example-8-building-dependencies-between-parameters"></a>Example 8: Building dependencies between parameters

Macros may be used to inter-depend parameters of defined types or classes. In
other words, if one parameter is altered by user, others should be adjusted
automatically, unless user specify them explicitly. For example we may define
macros `'foo::a'` and `'foo::b'` as follows:

```ruby
# mymodule/lib/puppet/parser/macros/foo/a.rb
Puppet::Parser::Macros.newmacro 'foo::a' do |a|
  (a.empty? or a.equal?(:undef)) ? 'default a' : a
end
```

```ruby
# mymodule/lib/puppet/parser/macros/foo/b.rb
Puppet::Parser::Macros.newmacro 'foo::b' do |b, a|
  (b.empty? or b.equal?(:undef)) ? "default b for a=#{a.inspect}" : b
end
```

and the following manifest in *mymodule/manifests/foo.pp* file

```puppet
# mymodule/manifests/foo.pp
define mymodule::foo_impl($a, $b) {
  notify{$title: message => "${title}: a=\'${a}\', b=\'${b}\'"}
}
define mymodule::foo($a = undef, $b = undef)
{
  $_a = determine('foo::a', $a)
  $_b = determine('foo::b', $b, $_a)
  mymodule::foo_impl{"$title": a => $_a , b => $_b}
}
```

Now, if we run the following command:

```console
puppet apply --modulepath $(pwd) <<!
mymodule::foo {defaults: }
mymodule::foo {custom_a: a => 'custom a' }
mymodule::foo {custom_b: b => 'custom b' }
mymodule::foo {custom_a_and_b: a => 'custom a', b => 'custom b' }
mymodule::foo {other: }
Mymodule::Foo[other] { a => 'other default a' }
!
```

we shall see these lines at output:

```console
Notice: defaults: a='default a', b='default b for a="default a"'
Notice: custom_a: a='custom a', b='default b for a="custom a"'
Notice: custom_b: a='default a', b='custom b'
Notice: custom_a_and_b: a='custom a', b='custom b'
Notice: other: a='other default a', b='default b for a="other default a"'
```

|[Table of Contents](#table-of-contents)|

##<a id="reference"></a>Reference

###<a id="function-reference"></a>Function reference

####<a id="index-of-functions"></a>Index of functions:

* [determine](#determine)
* [invoke](#invoke)

####<a id="determine"></a>determine
Determine value of a macro.

This function ivokes a macro defined with `Puppet::Parser::Macros.newmacro`
method and returns it's value. The function takes macro name as first
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

- *Type*: rvalue

|[Index of functions](#index-of-functions)|[Table of Contents](#table-of-contents)|

####<a id="invoke"></a>invoke
Invoke macro as a statement.

This function ivokes a macro defined with `Puppet::Parser::Macros.newmacro`
method and returns nil (that is it doesn't return any value to puppet).
The function takes macro name as first argument and macro parameters as the
rest of arguments. The number of arguments provided by user is validated
against the macro's arity.

*Example*:

Let say, you have defined the following macro in
*puppet/parser/macros/print.rb*:

    # puppet/parser/macros/print.rb
    Puppet::Parser::Macros.newmacro 'print' do |msg|
      print msg
    end

You may then invoke the macro from puppet as follows:

    invoke('print',"hello world!\n")

- *Type*: statement

|[Index of functions](#index-of-functions)|[Table of Contents](#table-of-contents)|

###<a id="api-reference"></a>API Reference

API reference may be generated with

```console
bundle exec rake yard
```

The generated documentation goes to `doc/` directory. Note that this works only
under ruby >= 1.9.

|[Table of Contents](#table-of-contents)|

##Limitations

* Currently there is no possibility to define macro in puppet manifests, that is
  we only can define macro using ruby and use it in ruby or puppet. I believe
  this functionality may implemented as an additional parser function (call it
  `macro`) and it should work with the help of puppet lambdas, which are
  available in future parser.
* Currently there is no way to store and auto-generate documentation for macros.
  It should work similarly as for functions but its not implemented at the
  moment. This may be added in future versions.

|[Table of Contents](#table-of-contents)|
