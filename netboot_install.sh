#!/bin/bash

#setting up firewall rules and forwarding

iptables -F INPUT
iptables -F FORWARD
iptables -F OUTPUT
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

echo 1 > /proc/sys/net/ipv4/ip_forward
INET="wlp3s0"
INETIP="$(ifconfig $INET | sed -n '/inet /{s/.*inet //;s/ .*//;p}')"
iptables -t nat -A POSTROUTING -o $INET -j SNAT --to-source $INETIP
sudo apt install dnsmasq

if [ ! -f /etc/dnsmasq.conf ]; then cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak;fi

cat >/etc/dnsmasq.conf <<EOF
interface=enp0s25
dhcp-range=192.168.2.100,192.168.2.150,255.255.255.0,12h
dhcp-boot=pxelinux.0,pxeserver,192.168.2.10
enable-tftp
tftp-root=/srv/tftpboot
EOF

echo give network static ip 192.168.2.10
echo but do not set gateway

service dnsmasq restart

#now we setup nfs
apt install nfs-kernel-server

if [ ! -f /etc/exports ]; then cp /etc/exports /etc/exports.bak;fi
cat >/etc/exports <<'EOF'
/srv/debian-live *(ro,async,no_root_squash,no_subtree_check)	
EOF

exportfs -rv
