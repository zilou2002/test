# Takes the $services hash (one key at a time) from the bird::services class and turns it into:
# - an interface -> lo:$name
# - a bird (BGP) network routing config entry.
# - a health enforcer service: anycast_health_forcer
# - that's it, but this is where you expand on each "service" if you need more logic.
#   something like passing in special health enforcer parameters should happen here.
#
define bird::service (
  $ipaddress,
  $ensure         = 'present',
  $auto           = true,
  $community      = undef,
) {
  include bird::services

  if !$::disable_anycast {
    concat::fragment { "bird-config-${name}":
      ensure  => $ensure,
      target  => 'bird-config',
      order   => '50',
      content => template('bird/bird-announce.erb'),
    }

    bird::loopback { "lo:${name}":
      ensure    => $ensure,
      ipaddress => $ipaddress,
      auto      => $auto,
    }
  }
}
