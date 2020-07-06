# Class: bird::params
class bird::params {
  $package            = 'bird'
  $conf_dir           = '/usr/local/etc'
  $daemon_uid         = 'bird'
  $daemon_gid         = 'bird'
  $ensure             = $::lsbdistcodename ? {
    'precise' => '1.5.0-2015051819-precise',
    'trusty'  => '1.5.0+twitch1-2015082702-trusty',
    'xenial'  => '1.5.0+twitch1-2016020404-xenial',
    'bionic'  => '1.5.0+twitch1-2016020404-bionic',
    default   => undef
  }
  $ospf_area          = hiera('ospf_area', '0.0.0.0')
  $include_file       = undef
  $protocol           = 'bgp'
  $bgp_announce       = undef
  $bgp_asn            = undef
  $bgp_community      = undef
  $require_routing    = true
  $daemontools_ensure = 'present'
  $daemontools_down   = undef
}
