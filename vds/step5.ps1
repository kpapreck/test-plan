$VDSw = "NetApp HCI VDS 01"
$vds = Get-VDSwitch -Name $VDSw
$nic1 = "vmnic0"
$nic2 = "vmnic1"
$esxihost = "winf-evo3-blade4.ntaplab.com"
$uplink1 = "Uplink 1"
$uplink2 = "Uplink 2"
$switch = "vSwitch0"
$vmhost = $esxihost
$iscsiA = "NetApp HCI VDS 01-iSCSI-A"
$iscsiB = "NetApp HCI VDS 01-iSCSI-B"
$vmotion = "NetApp HCI VDS 01-vMotion"
$subnet = "255.255.255.0"

$vds = Get-VDSwitch -Name $VDSw
$vmhost_array = Get-VMHost $esxihost

foreach ($vmhost in $vmhost_array)
{

#$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic2
#Write-Host  -Object "Adding vmnic (redundant) to $vds"
#Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

#Migrate VMkernel interfaces to VDS

# Management #
#$mgmt_portgroup = "Management Network"
#Write-Host "Migrating" $mgmt_portgroup "to" $VDSw
#$dvportgroup = Get-VDPortgroup -name $mgmt_portgroup -VDSwitch $vds
#$vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $vmhost
#Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-Null



#Write-Host  -Object 'Removing vnic from vswitch'
#$vmhost |Get-VMHostNetworkAdapter -Name $nic1 |Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
#$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic1
#Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

#Remove-VirtualSwitch -VirtualSwitch $switch -Confirm:$false

Write-Host "Adding $iscsiA Port Group"
$ip1 = Read-Host "Enter iSCSI-A IP for $vmhost"
New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiA -virtualSwitch $VDSw -IP $ip1 -SubnetMask $subnet -Mtu 9000 

Write-Host "Adding $iscsiB Port Group"
$ip2 = Read-Host "Enter iSCSI-B IP for $vmhost"
New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiB -virtualSwitch $VDSw -IP $ip2 -SubnetMask $subnet -Mtu 9000

Write-Host "Adding $vmotion Port Group"
$ip3 = Read-Host "Enter vMotion IP for $vmhost"
New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $vmotion -virtualSwitch $VDSw -IP $ip3 -SubnetMask $subnet -Mtu 9000 -VMotionEnabled $true








}
