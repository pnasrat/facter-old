Facter.add(:serialnumber) do
    confine :operatingsystem => :"hp-ux"
    setcode '/bin/getconf MACHINE_SERIAL'
end
