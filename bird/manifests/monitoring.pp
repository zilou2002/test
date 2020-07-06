# Provides virtual resources to monitor bird.
#
class bird::monitoring {
  twitch_servicecheck::passive { 'bird':
    command => 'check_procs -C bird',
  }
}
