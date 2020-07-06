Exec{
    path => '/usr/bin:/bin:/usr/sbin:/sbin'
}
node default {
    bird::loopback { 'lo:1':
        ipaddress => '127.0.0.2',
        #ensure    => 'absent'
    }
}
