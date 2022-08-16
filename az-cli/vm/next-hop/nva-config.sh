#!/bin/bash

## Install Net Tools
echo "Install Net Tools"
apt install net-tools

## Enable IP Forwarding
echo "Enable IP Forwarding"
sudo sed -i 's/#net\.ipv4\.ip_forward=1/net\.ipv4\.ip_forward=1/g' /etc/sysctl.conf


## Enable the Routing
echo "Enable the Routing"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE


## Install Software to save IPTables on reboot
echo "Install software to save iptables on reboot"
sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
sudo iptables-save | sudo tee -a /etc/iptables/rules.v4


## Add the Routes (eth1 = private, eth0 = internet)
echo "Add Route to NIC's"
sudo ip route add 10.2.0.0/23 via 10.2.0.1 dev eth1 && \
sudo ip route add 168.63.129.16 via 10.2.0.1 dev eth1 proto dhcp src 10.2.0.4


## Force IPTables and Routing on Boot
echo "Force IPTables and Routing on Boot"
echo '#!/bin/bash
/sbin/iptables-restore < /etc/iptables/rules.v4
sudo ip route add 10.2.0.0/23 via 10.2.0.1 dev eth1
sudo ip route add 168.63.129.16 via 10.2.0.1 dev eth1 proto dhcp src 10.2.0.4' | sudo tee -a /etc/rc.local && sudo chmod +x /etc/rc.local

## Rebooting
echo "Rebooting"
sudo reboot
