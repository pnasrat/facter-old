module Facter::Util::Solaris

  def self.zones()
    zones = []
    output = get_zone_output().split("\n")
    output.slice!(0)
    output.each do |line| 
       zones.push(line.split()[1,2])
    end
    zones
  end

  def self.get_zone_output()
    output = %x{/usr/sbin/zoneadm list -cv}
  end

end
