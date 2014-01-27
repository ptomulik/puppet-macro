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
