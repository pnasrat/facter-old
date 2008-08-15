require 'facter/util/solaris'

Facter.add(:zonename) do
    confine :kernel => :SunOS
    setcode do
        %{/usr/bin/zonename} if Facter.value(:kernelversion).to_f >= 5.10
    end
end

if Facter.value(:kernel) == "SunOS"
    zones = Facter::Util::Solaris.zones()

    if zones.length > 0 then
        Facter.add(:zones) do
           setcode do 
               "#{zones.length}"
           end
        end
    end

    zones.each do |zonename, state| 
        Facter.add("zone_#{zonename}") do
            setcode do
                state.to_s
            end
        end
    end
end
