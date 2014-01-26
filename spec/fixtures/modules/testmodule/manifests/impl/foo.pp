# manifests/impl/foo.pp
define testmodule::impl::foo($a, $b) {
  notify{$title: message => "${title}: a=\'${a}\', b=\'${b}\'"}
}
