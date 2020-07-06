# Class: bird
#
# installs and configures BIRD:
# Internet Routing Daemon
class bird(
  $package            = $bird::params::package,
  $daemon_uid         = $bird::params::daemon_uid,
  $daemon_gid         = $bird::params::daemon_gid,
  $ensure             = $bird::params::ensure,
  $syslog_host        = undef,
  $protocol           = $bird::params::protocol,
  $bgp_asn            = $bird::params::bgp_asn,
  $bgp_announce       = $bird::params::bgp_announce,
  $bgp_community      = $bird::params::bgp_community,
  $require_routing    = $bird::params::require_routing,
  $daemontools_ensure = $bird::params::daemontools_ensure,
  $daemontools_down   = $bird::params::daemontools_down,
  $instances          = undef,
  $services           = undef,
) inherits bird::params {

  validate_string($ensure)

  anchor { '::bird::begin': }
  -> class { '::bird::install': }
  -> class { '::bird::syslog': }
  -> Bird::Loopback <| |>
  -> Bird::Daemon <| |>
  -> anchor { '::bird::end': }
}
