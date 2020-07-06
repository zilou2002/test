# bgp_neighbors.rb
# Calculates BGP neighbor IPs for a server. The BGP neighbors will always be
# +1 and +2 from the subnet of the server.

require 'ipaddr'

# Get the subnet address bond0/team0
# For example, 10.23.12.245/24 returns 10.23.12.0
def get_subnet()
  primary_ip = IPAddr.new Facter.value(:ipaddress_primary)
  primary_mask = Facter.value(:netmask_primary)
  return primary_ip.mask(primary_mask)
end

# Add n to the last subnet of ip
# For example, (10.23.12.0, 1) returns 10.23.12.1
def add_to_last_octet(ip, n)
  ret = ip
  n.times do
    ret = ret.succ
  end
  return ret
end

Facter.add('twitch_bgp_neighbor_da01') do
  confine :ipaddress_primary => /^[0-9]+\./
  setcode do
    primary_subnet = get_subnet()
    add_to_last_octet(primary_subnet, 1).to_s
  end
end

Facter.add('twitch_bgp_neighbor_da02') do
  confine :ipaddress_primary => /^[0-9]+\./
  setcode do
    primary_subnet = get_subnet()
    add_to_last_octet(primary_subnet, 2).to_s
  end
end
