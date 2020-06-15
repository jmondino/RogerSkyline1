#!/bin/bash

IPT=iptables

#DISABLE AND DROP EVERYTHNG
$IPT -t filter -F
$IPT -t filter -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

#Authorize packets from established connections
$IPT -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPT -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

#Authorize ssh
$IPT -A INPUT -p tcp --dport 2323 -j ACCEPT

#Authorize HTTP HTTPS
$IPT -A OUTPUT -p tcp -m multiport --dport 80,443 -j ACCEPT
$IPT -A INPUT -p tcp -m multiport --dport 80,443 -j ACCEPT

#Authorize DNS
$IPT -A OUTPUT -p tcp --dport 53 -j ACCEPT
$IPT -A OUTPUT -p udp --dport 53 -j ACCEPT

#Authorize lo
$IPT -A INPUT -i lo -j ACCEPT

#Authorize pings
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT

#Disable pings
#$IPT -t mangle -A PREROUTING -p icmp -j DROP

#Block invalid packets ACK (who skipped first 2 step of 3WHS)
$IPT -t mangle -A PREROUTING -m state --state INVALID -j DROP
$IPT -t mangle -A PREROUTING -p tcp ! --syn -m state --state NEW -j DROP

#Block fragmentation TCP
$IPT -t mangle -A PREROUTING -f -j DROP

#Block uncommon MSS value
$IPT -t mangle -A PREROUTING -p tcp -m state --state NEW -m tcpmss ! --mss 536:65535 -j DROP

#Block packets with bogus TCP flags
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
$IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP