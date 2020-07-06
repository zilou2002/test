# Class: bird::multiservice
#
# Installs bird and manages a configuration for multiple services
# When using this class, there should not be any other clases that
# call bird::daemon separately.
#
# Parameters:
#
# [*hiera_merge*]
#  Determine whether to use hiera() or hiera_array().  True (default) will call hiera_array().
#   Type: Bool
#
# ex.
# Hiera:
#  ---
#  bird::multiservice::hiera_merge: true
#  bird::multiservice::instances
#   - name: myservice
#     bgp_community: 12345
#     bgp_announce:
#      - '192.168.100.100'
#   - name: anotherservice
#     bgp_community: 34100
#     bgp_announce:
#      - '10.10.10.99'
#
class bird::multiservice (
  $hiera_merge = true,
) {

  validate_bool($hiera_merge)

  $instances = $hiera_merge ? {
    true    => hiera_array('bird::multiservice::instances'),
    default => hiera('bird::multiservice::instances'),
  }

  include bird

  bird::daemon{ 'multiservice':
    instances => $instances,
  }
}
