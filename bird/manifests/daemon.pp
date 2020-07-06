# each bird daemon needs:
# 1 config
# 1 supervise entry
define bird::daemon(
  $template              = 'bird/bird.conf.erb',
  $consul_template       = undef,
  $conf_dir              = $bird::params::conf_dir,
  $daemon_uid            = $bird::params::daemon_uid,
  $daemon_gid            = $bird::params::daemon_gid,
  $ospf_area             = $bird::params::ospf_area,
  $include_file          = $bird::params::include_file,
  $routed_subnet         = undef,
  $routed_subnet_service = undef,
  $protocol              = $bird::protocol,
  $bgp_asn               = $bird::bgp_asn,
  $bgp_announce          = $bird::bgp_announce,
  $bgp_community         = $bird::bgp_community,
  $instances             = [],
  $daemontools_ensure    = $bird::daemontools_ensure,
  $daemontools_down      = $bird::daemontools_down,
) {
  include bird

  $filter_line = join(delete_undef_values(flatten([$bgp_announce,$routed_subnet])),', ')

  # Default value for $instances is []
  validate_array($instances)

  # each daemon should include these syslog resources
  $require_routing = $bird::require_routing

  validate_re($protocol, ['^ospf$', '^bgp$'])
  validate_bool($require_routing)

  if (($protocol == 'bgp') and ($require_routing) and (! $instances[0]) ) {
    # If we're in a BGP rack, make sure the necessary values are set
    validate_string($::twitch_bgp_neighbor_da01)
    validate_string($::twitch_bgp_neighbor_da02)
    validate_integer($bgp_asn)
    validate_integer($bgp_community)
  }

  $file_prefix    = "bird_${name}"
  $pid_file       = "/var/run/${file_prefix}.pid"
  # command itself does not return proper exit codes
  # use verbose output from birdc to get error codes printed out
  # use grep to verify existence of an OK configuration:
  #   ex. 0003 Reloaded
  # this allows puppet to react to a non-zero exit code
  $reload_command = "birdc -v -s /var/run/${file_prefix}.ctl configure | grep -q 0003"

  # Separate included config file which consul-template will fill out (and
  # update when the data in consul changes)
  if $consul_template {
    # this might be used by the main configuration template
    $consul_template_output = "${file_prefix}_consul.conf"
    $consul_template_input  = "${file_prefix}_consul.conf.ctpl"

    file { "${conf_dir}/${consul_template_input}":
      ensure  => 'present',
      content => template($consul_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

    consul_template::service{ $file_prefix:
      source      => "${conf_dir}/${consul_template_input}",
      destination => "${conf_dir}/${consul_template_output}",
      command     => $reload_command,
      before      => Daemontools::Supervise[$file_prefix],
    }

    # TODO: remove after migration
    daemontools::supervise { "consul_template_${file_prefix}":
      down   => 'force',
      syslog => 'local3',
      daemon => '/usr/bin/consul-template -consul 127.0.0.1:8500 2>&1',
      wd     => $conf_dir
    }
  }

  file { "${conf_dir}/${file_prefix}.conf":
    ensure  => $daemontools_ensure,
    content => template($template),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec[$reload_command],
  }

  # reloads bird daemon with new configuration
  exec { $reload_command:
    refreshonly => true,
    user        => 'bird',
    require     => Daemontools::Supervise[$file_prefix],
    try_sleep   => 3,
    tries       => 3,
    timeout     => 3,
  }

  $daemon_args = join([
    "-c ${conf_dir}/${file_prefix}.conf", # config
    "-P ${pid_file}",                     # pid
    "-s /var/run/${file_prefix}.ctl",     # socket
    "-u ${daemon_uid}",                   # user
    "-g ${daemon_gid}",                   # gid
    '-f',                                 # foreground (daemontools)
  ], ' ')

  # readability: concat
  $predaemon = join([
    "touch ${pid_file}",
    "chown ${daemon_uid}:${daemon_gid} ${pid_file}",
  ], ' && ')


  daemontools::supervise { $file_prefix:
    ensure    => $daemontools_ensure,
    down      => $daemontools_down,
    syslog    => 'local3',
    predaemon => [$predaemon],
    daemon    => "bird ${daemon_args} 2>&1",
    wd        => '/',
    require   => File["${conf_dir}/${file_prefix}.conf"],
  }
}
