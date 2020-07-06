# Creates a loopback interface for an anycast IP address.
#
define bird::loopback (
  $ipaddress,
  $ensure = 'present',
  $auto   = false,
) {
  # include bird for higher level ordering
  include bird

  # make sure we're creating sane interface names: lo:1 eth0:1
  validate_re($name, '^[a-z]+(?:\d*):\w+$', "'${name}' is not a valid interface alias")
  validate_re($ipaddress, '^\d+\.\d+\.\d+\.\d+$', "'${ipaddress}' is in CIDR format, must be only IPaddress")

  # does the heavy lifting of the interfaces file
  interfaces::interface { $name:
    ensure    => $ensure,
    auto      => $auto,
    method    => 'static',
    ipaddress => $ipaddress,
  }
}
