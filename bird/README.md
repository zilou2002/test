# Bird

## Overview

Installs and configures bird internet routing daemon.

We have a custom package that was packaged with Bird 1.4.0, from branch
`add-path`

Main class will install Bird, but not configure a daemon.

## Usage (multiple services)

At some point in history twitch began moving to BGP from OSPF for inter-rack routing.
Someone made a `bird::multiservice` class that allowed users of BGP to configure
more than one routed subnet/address on a host. That's great and all, but it still
required users to configure the loopback (anycast) interface and the anycast
health enforcer separately. This approach means you have to configure some of
the service in hiera and the rest in a manifest; the logic is hard to follow.

Now we have a new class named `bird::services` which brings a hash of hashes in from hiera
and creates multiple anycast and bird resources. Instead of configuring the loopback
and health enforcer separately from the bgp announcement, it's now all in one instantiation.
It is possible to call `bird::services` from a manifest. You may also call `bird::service`
directly to create an announcement, interface and health enforcer from manifests.

The parameters available for each service are found in [bird::service](manifests/service.pp)
and roughly match what you'll find in [bird::loopback](manifests/loopback.pp) and
[twitch_anycast::health_enforcer::daemon](../twitch_anycast/manifests/health_enforcer/daemon.pp).

### Example Usage

Add a stanza similar to the following to a hiera file. Multiple services
may be placed in different hiera files; the hashes are merged.

```yaml
---
classes:
  - bird::services
bird::services::static_subnet: '10.254.0.0/22'
bird::services::static_community: 16012
bird::services:
  unbound:
    ipaddress: '10.254.0.17'
    community: 16001
  roldap:
    ipaddress: '10.254.0.18'
    community: 16019
    check_command: "/usr/lib/nagios/plugins/check_ldaps --port 636 -H localhost -b 'dc=justin,dc=tv'"
    alert_email: 'systems-anycast-alerts@justin.tv'
    auto: false
  squid:
    ipaddress: '10.254.0.19'
    community: 16009
    check_command: "/usr/local/nagios/jtv/check_http_proxy.py --proxy=127.0.0.1:9797 --url=http://google.com"
    alert_email: 'systems-anycast-alerts@justin.tv'
    auto: true
    no_op: true
```

The above example creates three anycast interfaces, three bird BGP announcements
for single-addresses (/32s) and a BGP announcement for a CIDR: 10.254.0.0/22.
The static subnet is great for something like a VPN server's client IP range.
One of the three anycast interfaces will not start automatically and will instead
have a health enforcer bring it up and down. The last one shown above will start
the health enforcer in no-op mode: it'll only send alerts but wont touch the interface.

## Usage (single service)

Calling `bird::service` directly in a manifest is the preferred method to create
a single anycast announcement. Example:
```puppet
  bird::service { 'service':
    ipaddress     => '10.255.254.233',
    community     => 16110,
  }
```
Defining a `check_*` param will enable the anycast health enforcer daemon.


The following is the "old" and original way bird worked. This was designed when
we used OSPF exclusively and got adapted as we rolled out BGP.

To install and configure a daemon, use the `bird::daemon` define:

```puppet

   include ::bird

   bird::daemon { 'cdncache': }
```

Note: Now that we use BGP, **you may not call `bird::daemon` more than one time on
a single host.** If you have multiple anycast interfaces to announce via BGP, you
must use `bird::services` (explained above) or [bird::multiservice](manifests/multiservice.pp).

### Loopbacks

We we need to create loopbacks for some usage of bird, so there is a define to help
do that.

The define will create the interface in `/etc/network/interfaces` file using `Augeas`.

```puppet
  bird::loopback { 'lo:1':
    ipaddress => '127.0.0.2'
  }
```
