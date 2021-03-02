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
$vmhost_array = Get-VMHost $esxihost

foreach ($vmhost in $vmhost_array)
{

$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic2
Write-Host  -Object "Adding vmnic (redundant) to $vds"
Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false










}
