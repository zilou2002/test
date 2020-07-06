# bird daemons generically send all syslog to local disk unless configured with a $syslog_host
class bird::syslog inherits bird {
  $_ensure = $bird::syslog_host ? {
    undef   => absent,
    ''      => absent,
    default => present,
  }
  ::rsyslog::snippet { '30-bird':
    content => ":programname, startswith, \"bird\" @${bird::syslog_host}\n",
    ensure => $_ensure,
  }
}
