#!/bin/bash
echo "Enter Management VLAN"
read mvlan

sed 's/vlan 2541-2543/vlan 2542-2543/' 2-cable-HCIow-sw-a-DNS-DHCP.txt > 2-cable-HCIow-sw-a-DNS-DHCP-mod.txt
sed 's/2541/'$mvlan'/g' 2-cable-HCIow-sw-a-DNS-DHCP-mod.txt > 2-cable-HCIow-sw-a-DNS-DHCP-mod2.txt
sed '1,/vlan 4000/ {/vlan 4000/a\
vlan '$mvlan'
}' 2-cable-HCIow-sw-a-DNS-DHCP-mod2.txt > 2-cable-HCIow-sw-a-DNS-DHCP-modified.txt 
rm 2-cable-HCIow-sw-a-DNS-DHCP-mod.txt
rm 2-cable-HCIow-sw-a-DNS-DHCP-mod2.txt

#switch b configuration file
sed 's/vlan 2541-2543/vlan 2542-2543/' 2-cable-HCIow-sw-b-DNS-DHCP.txt > 2-cable-HCIow-sw-b-DNS-DHCP-mod.txt
sed 's/2541/'$mvlan'/g' 2-cable-HCIow-sw-b-DNS-DHCP-mod.txt > 2-cable-HCIow-sw-b-DNS-DHCP-mod2.txt
sed '1,/vlan 4000/ {/vlan 4000/a\
vlan '$mvlan'
}' 2-cable-HCIow-sw-b-DNS-DHCP-mod2.txt > 2-cable-HCIow-sw-b-DNS-DHCP-modified.txt
rm 2-cable-HCIow-sw-b-DNS-DHCP-mod.txt
rm 2-cable-HCIow-sw-b-DNS-DHCP-mod2.txt
