# ex: syntax=ruby si sw=2 ts=2 et
require 'ipaddr'

module PuppetX; end

class PuppetX::Ip

  attr_reader :cidr, :address, :prefixlength

  def initialize(cidr)
    @cidr = IPAddr.new(cidr)
    (addr, prefixlen) = cidr.split(/\//)
    @address = IPAddr.new(addr)
    prefixlen ||= unicast_prefixlength
    @prefixlength = prefixlen.to_i
  end

  def netmask
    IPAddr.new(unicast_netmask).mask(prefixlength).to_s
  end

  def cidrlength
    prefixlength.to_s
  end

  def network_size
    range.count
  end

  def network(offset = 0)
    raise ArgumentError, 'offset out of bounds' if offset > network_size
    "#{range.to_a[offset].to_s}/#{prefixlength}"
  end

  def broadcast(offset = 0)
    raise ArgumentError, 'offset out of bounds' if offset > network_size
    "#{range.to_a[offset - 1].to_s}/#{prefixlength}"
  end

  def offset
    range.to_a.index(address)
  end

  def split
    [ subnet(prefixlength + 1, 0), subnet(prefixlength + 1, 1) ]
  end

  def subnet(subnet_prefixlength, index)
    raise ArgumentError, 'subnet prefix too long' if subnet_prefixlength <= prefixlength
    subnet_size = 2 ** (unicast_prefixlength - subnet_prefixlength)
    raise ArgumentError, 'subnet index out of bounds' if (subnet_size * index) >= network_size
    "#{range.to_a[subnet_size * index]}/#{subnet_prefixlength}"
  end

  def supernet(supernet_prefixlength)
    raise ArgumentError, 'supernet prefix too short' if supernet_prefixlength < 0
    "#{cidr.mask(supernet_prefixlength)}/#{supernet_prefixlength}"
  end

  def to_s
    address.to_s
  end

private

  def range
    cidr.to_range
  end

  def unicast_prefixlength
    address.ipv4? ? 32 : 128
  end

  def unicast_netmask
    address.ipv4? ? '255.255.255.255' : 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'
  end
end
