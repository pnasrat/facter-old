# A base module for collecting IP-related
# information from all kinds of platforms.
module Facter::Util::IP
    # A map of all the different regexes that work for
    # a given platform or set of platforms.
    REGEX_MAP = {
        :linux => {
            :ipaddress => /inet addr:([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,
            :macaddress  => /(?:ether|HWaddr)\s+(\w{1,2}:\w{1,2}:\w{1,2}:\w{1,2}:\w{1,2}:\w{1,2})/,
            :netmask => /Mask:([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/
        },
        :bsd => {
            :aliases => [:openbsd, :netbsd, :freebsd, :darwin],
            :ipaddress => /inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,
            :macaddress  => /(?:ether|lladdr)\s+(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w)/,
            :netmask => /netmask\s+0x(\w{8})/
        },
        :sunos => {
            :addr => /inet\s+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/,
            :macaddress  => /(?:ether|lladdr)\s+(\w?\w:\w?\w:\w?\w:\w?\w:\w?\w:\w?\w)/,
            :netmask => /netmask\s+(\w{8})/
        }
    }

    # Convert an interface name into purely alpha characters.
    def self.alphafy(interface)
        interface.gsub(/[:.]/, '_')
    end

    def self.convert_from_hex?(kernel)
        kernels_to_convert = [:sunos, :openbsd, :netbsd, :freebsd, :darwin]
        kernels_to_convert.include?(kernel)
    end

    def self.supported_platforms
        REGEX_MAP.inject([]) do |result, tmp|
            key, map = tmp
            if map[:aliases]
                result += map[:aliases]
            else
                result << key
            end
            result
        end
    end

    def self.get_interfaces
        int = nil

        output =  Facter::Util::IP.get_all_interface_output()

        # We get lots of warnings on platforms that don't get an output
        # made.
        if output
            int = output.scan(/^\w+[.:]?\d+/)
        else
            []
        end
    end

    def self.get_all_interface_output
        case Facter.value(:kernel)
        when 'Linux', 'OpenBSD', 'NetBSD', 'FreeBSD', 'Darwin'
            output = %x{/sbin/ifconfig -a}
        when 'SunOS'
            output = %x{/usr/sbin/ifconfig -a}
        end
        output
    end

    def self.get_single_interface_output(interface)
        output = ""
        case Facter.value(:kernel)
        when 'Linux', 'OpenBSD', 'NetBSD', 'FreeBSD', 'Darwin'
            output = %x{/sbin/ifconfig #{interface}}
        when 'SunOS'
            output = %x{/usr/sbin/ifconfig #{interface}}
        end
        output
    end

    def self.get_bonding_master(interface)
        if Facter.value(:kernel) != 'Linux'
            return nil
        end
        # We need ip instead of ifconfig because it will show us
        # the bonding master device.
        if not FileTest.executable?("/sbin/ip")
            return nil
        end
        regex = /SLAVE[,>].* (bond[0-9]+)/
            ethbond = regex.match(%x{/sbin/ip link show #{interface}})
        if ethbond
            device = ethbond[1]
        else
            device = nil
        end
        device
    end


    def self.get_interface_value(interface, label)
        tmp1 = []

        kernel = Facter.value(:kernel).downcase.to_sym

        # If it's not directly in the map or aliased in the map, then we don't know how to deal with it.
        unless map = REGEX_MAP[kernel] || REGEX_MAP.values.find { |tmp| tmp[:aliases] and tmp[:aliases].include?(kernel) }
            return []
        end

        # Pull the correct regex out of the map.
        regex = map[label.to_sym]

        # Linux changes the MAC address reported via ifconfig when an ethernet interface
        # becomes a slave of a bonding device to the master MAC address.
        # We have to dig a bit to get the original/real MAC address of the interface.
        bonddev = get_bonding_master(interface)
        if label == 'macaddress' and bonddev
            bondinfo = IO.readlines("/proc/net/bonding/#{bonddev}")
            hwaddrre = /^Slave Interface: #{interface}\n[^\n].+?\nPermanent HW addr: (([0-9a-fA-F]{2}:?)*)$/m
            value = hwaddrre.match(bondinfo.to_s)[1].upcase
        else
            output_int = get_single_interface_output(interface)

            if interface != "lo" && interface != "lo0"
                output_int.each do |s|
                    if s =~ regex
                        value = $1
                        if label == 'netmask' && convert_from_hex?(kernel)
                            value = value.scan(/../).collect do |byte| byte.to_i(16) end.join('.')
                        end
                        tmp1.push(value)
                    end
                end
            end

            if tmp1
                value = tmp1.shift
            end
        end
    end
end
