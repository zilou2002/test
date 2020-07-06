# Fact: :bird_version
#
# Purpose: retrieve installed bird version
#

Facter.add(:bird_version) do
    setcode do
        osfamily = Facter.value('osfamily')
        case osfamily
        when "Debian"
            command='/usr/bin/dpkg-query -f \'${Status};${Version};\' -W bird 2>/dev/null'
            version = Facter::Util::Resolution.exec(command)
            if version =~ /.*install ok installed;([^;]+);.*/
                $1
            else
                nil
            end
        when "RedHat", "Suse"
            command='rpm -qa --qf "%{VERSION}" "bird"'
            version = Facter::Util::Resolution.exec(command)
            if version =~ /^(.+)$/
                $1
            else
                nil
            end
        else
            nil
        end
    end
end
