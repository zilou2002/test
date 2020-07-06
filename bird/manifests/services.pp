# Class: bird::services
#
# Installs bird and manages a configuration for multiple BGP services.
# When using this class, there should not be any other clases that
# call bird::daemon or bird::multiservice.
#
# This class is designed to replace bird::multiservice and bird::daemon while
# combining bird::loopback and twitch_anycast::health_enforcer features into one class.
#
#
# ex.
# Hiera:
#  ---
#  classes:
#    - bird::services
#  bird::services:
#    myservice:
#      community: 12345
#      ipaddress: '192.168.100.100'
#    anotherservice:
#      community: 34100
#      ipaddress: '10.10.10.99'
#      auto: false
#      health_url: http://localhost:54677
#
# The above will create two loopback & BGP instances: lo:myservice and lo:anotherservice
# The interface for lo:myservice will come up automatically. The other loopback interface
# uses anycast health enforcer for control.

class bird::services (
  $static_subnet    = undef,
  $static_community = $bird::bgp_community,
) inherits bird {
  $services = hiera_hash('bird::services', $bird::services)
  # The following code configures the bird daemon on a host.
  $reload   = '/usr/local/sbin/birdc -v -s /run/twitch_bird/ctl configure | grep -q 0003'

  validate_string($::twitch_bgp_neighbor_da01)
  validate_string($::twitch_bgp_neighbor_da02)
  validate_integer($bird::bgp_asn)

  if !$::disable_anycast {

    concat { 'bird-config':
      path   => "${bird::conf_dir}/bird_service.conf",
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      notify => Exec[$reload],
    }

    # This template contains most of the config for bird.
    concat::fragment { 'bird-config-header':
      target  => 'bird-config',
      order   => '01',
      content => template('bird/bird-header.conf.erb'),
    }

    # This creates a snippet of bird.conf config for each interface defined in hiera.
    # Also creates the lo:service interfaces and anycast health enforcer.
    if !empty($services) {
      create_resources('bird::service', $services)
    }
    # This runs refacter after all anycast interfaces come up.
    Bird::Loopback <| |> ~> refacter { 'bird_loopback_facts':
      patterns => ['^ipaddress_lo_'],
    }

    # And this small fragment closes the announce_out stanza in the template.
    concat::fragment { 'bird-config-footer':
      target  => 'bird-config',
      order   => '99',
      content => template('bird/bird-footer.conf.erb'),
    }

    # reloads bird daemon with new configuration
    exec { $reload:
      refreshonly => true,
      user        => 'bird',
      try_sleep   => 3,
      tries       => 3,
      timeout     => 3,
      require     => Twitch_systemd::Service['bird'],
    }

    twitch_systemd::service { 'bird':
      command           => '/usr/local/sbin/bird',
      options           => join([
        "-c ${bird::conf_dir}/bird_service.conf", # config
        '-P /run/twitch_bird/pid',
        '-s /run/twitch_bird/ctl', # socket
        '-u', $bird::daemon_uid,
        '-g', $bird::daemon_gid,
        '-f', # foreground
      ], ' '),
      user              => 'root',
      reload            => "/bin/sh -c \"${reload}\"",
      execpre           => [
        '/bin/mkdir -p /run/twitch_bird',
        "/bin/chown ${bird::daemon_uid}:${bird::daemon_gid} /run/twitch_bird",
      ],
      restart_on_change => false,
      require           => Concat['bird-config'],
    }
  }
}
