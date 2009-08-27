require 'socket'

Facter.add(:fqdn) do
    setcode do
        Socket.gethostbyname(Socket.gethostname).first
    end
end
