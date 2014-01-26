# manifests/foo.pp
define testmodule::foo_impl($a, $b) {
  notify{$title: message => "${title}: a=\'${a}\', b=\'${b}\'"}
}
define testmodule::foo($a = undef, $b = undef)
{
  $_a = determine('foo::a', $a)
  $_b = determine('foo::b', $b, $_a)
  testmodule::foo_impl{"$title":
    a => $_a,
    b => $_b
  }
}
