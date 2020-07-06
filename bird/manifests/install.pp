# Installs bird package and associated users.
class bird::install(
  $package    = $bird::package,
  $daemon_uid = $bird::daemon_uid,
  $daemon_gid = $bird::daemon_gid,
  $ensure     = $bird::ensure,
  $conf_dir   = $bird::conf_dir,
) inherits bird {
  # install package
  package { $package:
    ensure => $ensure
  }

  # we should remove the default config in the package
  file { "${conf_dir}/bird.conf":
    ensure  => 'absent',
    require => Package[$package]
  }

  # create user and group
  group { $daemon_gid:
    ensure     => 'present',
    system     => true,
    forcelocal => true,
    require    => Package[$package],
  }

  user { $daemon_uid:
    ensure     => 'present',
    system     => true,
    forcelocal => true,
    gid        => $daemon_gid,
    require    => Group[$daemon_gid],
  }
}
