# memory.rb
# Additional Facts for memory/swap usage
#
# Copyright (C) 2006 Mooter Media Ltd
# Author: Matthew Palmer <matt@solutionsfirst.com.au>
#
#
require 'facter/util/memory'

{   :MemorySize => "MemTotal",
    :MemoryFree => "MemFree",
    :SwapSize   => "SwapTotal",
    :SwapFree   => "SwapFree"
}.each do |fact, name|
    Facter.add(fact) do
        confine :kernel => :linux
        setcode do
            Facter::Memory.meminfo_number(name)
        end
    end
end

if Facter.value(:kernel) == "AIX"
    swap = Facter::Util::Resolution.exec('swap -l')
    swapfree, swaptotal = 0, 0
    swap.each do |dev|
        if dev =~ /^\/\S+\s.*\s+(\S+)MB\s+(\S+)MB/
            swaptotal += $1.to_i
            swapfree  += $2.to_i
        end
    end

    Facter.add("SwapSize") do
        confine :kernel => :aix
        setcode do
            Facter::Memory.scale_number(swaptotal.to_f,"MB")
        end
    end

    Facter.add("SwapFree") do
        confine :kernel => :aix
        setcode do
            Facter::Memory.scale_number(swapfree.to_f,"MB")
        end
    end
end
if Facter.value(:kernel) == "HP-UX"
    # no MemoryFree because hopefully there is none
    if FileTest.exists?("/opt/ignite/bin/print_manifest")
        mem = %x{/opt/ignite/bin/print_manifest}.split(/\n/).grep(/Main Memory:/).collect{|l| l.split[2]}
        Facter.add(:MemorySize) do
            setcode do
                Facter::Memory.scale_number(mem[0].to_f,"MB")
            end
        end
    end
    swapt = %x{/usr/sbin/swapinfo -dtm}.split(/\n/).grep(/^total/)
    swap  = swapt[0].split[1]
    swapf = swapt[0].split[3]
    Facter.add("SwapTotal") do
        setcode do
            Facter::Memory.scale_number(swap.to_f,"MB")
        end
    end
    Facter.add("SwapFree") do
        setcode do
            Facter::Memory.scale_number(swapf.to_f,"MB")
        end
    end
end
