$VDSw = "NetApp HCI VDS 01"
$vds = Get-VDSwitch -Name $VDSw
$nic1 = "vmnic0"
$nic2 = "vmnic1"
$esxihost = "winf-evo3-blade4.ntaplab.com"
$uplink1 = "Uplink 1"
$uplink2 = "Uplink 2"
$switch = "vSwitch0"
$vmhost = $esxihost
$vds = Get-VDSwitch -Name $VDSw

#$vds | Add-VDSwitchVMHost -VMHost $esxihost | Out-Null

# Migrate pNICs to VDS
$vmhostNetworkAdapter = Get-VMHost $esxihost | Get-VMHostNetworkAdapter -Physical -Name $nic2
$vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$true

$vmhostNetworkAdapter = Get-VMHost $vmhost |Get-VirtualSwitch -Name "vSwitch0" |select -ExpandProperty Nic |select -First 1

Write-Host "Removing vnic from vswitch"

#$vmhost |Get-VMHostNetworkAdapter -Name $vmhostNetworkAdapter | Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
Get-VMHostNetworkAdapter -Name $vmhostNetworkAdapter | Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
Write-host "Fetching removed vnic into a variable"

$Phnic= $vmst |Get-VMHostNetworkAdapter -Physical -Name $vmhostNetworkAdapter

Write-Host "Adding vmnic (redundant) to" $vds

Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false




# Migrate first 2 nics to VDS
Write-Host "Adding $nic1 and $nic2 to" $VDSw
#  $vmhostNetworkAdapter = Get-VMHost $esxihost | Get-VMHostNetworkAdapter -Physical -Name $nic1
#  $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$true
#  $vmhostNetworkAdapter = Get-VMHost $esxihost | Get-VMHostNetworkAdapter -Physical -Name $nic2
#  $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$true


