#!/etc/sh

FW_start() {

## REINITIALISATION DES TABLES
iptables -F
iptables -t filter -F
iptables -t nat -F
iptables -t mangle -F


## BLOQUER TOUT LE TRAFIC ENTRANT DU WAN AU LAN MAIS AUTORISER CE QUI EST SORTANT ET CE QUI SE TRAVERSE 
iptables -A INPUT -i enp0s3 -j DROP
iptables -A OUTPUT -o enp0s3 -j ACCEPT
iptables -A FORWARD -i enp0s3 -j ACCEPT

## Ne pas interrompre les connexions dÈj‡ Ètablies
iptables -t filter -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t filter -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT


## AUTORISER LES REQUETES DNS:
iptables -A INPUT -i enp0s3 -p tcp --sport 53 -j ACCEPT

#AUTORISER LE TRAFIC NTP
iptables -A INPUT -p udp --dport 123 -j ACCEPT
iptables -A INPUT -p udp --sport 123:123 -m state --state ESTABLISHED -j ACCEPT

iptables -A OUTPUT -p udp --sport 123 -j ACCEPT
iptables -A OUTPUT -p udp --dport 123:123 -m state --state ESTABLISHED -j ACCEPT

#AUTORISER LE TRAFIC SMTP POUR LES MAIL
iptables -A INPUT -p tcp -dport 25 -j ACCEPT
iptables -A OUTPUT -p tcp -dport 25 -j ACCEPT

# REDIRECTION DU TRAFIC HTTP/HTTPS VERS SQUID
# POUR CHAQUE SOUS RESEAU

## VLAN 3 - Service OpÈrationnel
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.0/25 --dport 80 -j DNAT --to 192.168.1.162:3128
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.0/25 --dport 443 -j DNAT --to 192.168.1.162:3128

## VLAN 4 - Service Commercial
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.128/27 --dport 80 -j DNAT --to 192.168.1.162:3128
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.128/27 --dport 443 -j DNAT --to 192.168.1.162:3128

## VLAN 6 - Service DRH, Direction
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.176/28 --dport 80 -j DNAT --to 192.168.1.162:3128
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.176/28 --dport 443 -j DNAT --to 192.168.1.162:3128

## VLAN 7 - Service ComptabilitÈ
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.192/29 --dport 80 -j DNAT --to 192.168.1.162:3128
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.192/29 --dport 443 -j DNAT --to 192.168.1.162:3128

## VLAN 10 - Service IT
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.216/29 --dport 80 -j DNAT --to 192.168.1.162:3128
iptables -t nat -A PREROUTING -p tcp -s 192.168.1.216/29 --dport 443 -j DNAT --to 192.168.1.162:3128


#NAT ENTRE LAN et WAN
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

#DNAT entre WAN et DMZ
iptables -t nat -A PREROUTING -p tcp -d 192.168.179.139 --dport 80 -j DNAT --to 192.168.1.211
iptables -t nat -A PREROUTING -p tcp -d 192.168.179.139 --dport 443 -j DNAT --to 192.168.1.211

}



FW_stop() {

#SUPPRESSION DE TOUTES LES REGLES
iptables -F
iptables -t filter -F
iptables -t nat -F
iptables -t mangle -F

#AUTORISER N'IMPORTE QUEL TRAFIC
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

iptables -t filter -P INPUT ACCEPT
iptables -t filter -P FORWARD ACCEPT
iptables -t filter -P OUTPUT ACCEPT

iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT

iptables -t mangle -P PREROUTING ACCEPT
iptables -t mangle -P INPUT ACCEPT
iptables -t mangle -P FORWARD ACCEPT
iptables -t mangle -P OUTPUT ACCEPT
iptables -t mangle -P POSTROUTING ACCEPT

iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE

}

FW_restart(){
FW_stop;
sleep 3;
FW_start;

}


case "$1" in
'start')
FW_start
;;

'stop')
FW_stop
;;

'restart')
FW_restart
;;
*)
esac
