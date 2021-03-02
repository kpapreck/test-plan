# ESXi hosts to migrate from VSS to VDS
#$vmhost_array = @("vesxi55-1.primp-industries.com","vesxi55-2.primp-industries.com","vesxi55-3.primp-industries.com")

$vmhost_array = @("winf-evo3-blade4.ntaplab.com")

 
# Create VDS
$vds_name = "NetApp HCI VDS 01"
#Write-Host "`nCreating new VDS" $vds_name
#$vds = New-VDSwitch -Name $vds_name -Location (Get-Datacenter -Name "VSAN-Datacenter")
$vds = Get-VDSwitch -Name $vds_name
 
# Create DVPortgroup
#Write-Host "Creating new Management DVPortgroup"
#New-VDPortgroup -Name "Management Network" -Vds $vds | Out-Null
#Write-Host "Creating new Storage DVPortgroup"
#New-VDPortgroup -Name "Storage Network" -Vds $vds | Out-Null
#Write-Host "Creating new vMotion DVPortgroup"
#New-VDPortgroup -Name "vMotion Network" -Vds $vds | Out-Null
#Write-Host "Creating new VM DVPortgroup`n"
#New-VDPortgroup -Name "VM Network" -Vds $vds | Out-Null
 
foreach ($vmhost in $vmhost_array) {
# Add ESXi host to VDS
#Write-Host "Adding" $vmhost "to" $vds_name
#$vds | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null
 
# Migrate pNIC to VDS (vmnic0/vmnic1)
Write-Host "Adding vmnic0/vmnic1 to" $vds_name
$vmhostNetworkAdapter = Get-VMHost $vmhost | Get-VMHostNetworkAdapter -Physical -Name vmnic0
$vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$false
$vmhostNetworkAdapter = Get-VMHost $vmhost | Get-VMHostNetworkAdapter -Physical -Name vmnic1
$vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$false
 
# Migrate VMkernel interfaces to VDS
 
# Management #
$mgmt_portgroup = "Management Network"
Write-Host "Migrating" $mgmt_portgroup "to" $vds_name
$dvportgroup = Get-VDPortgroup -name $mgmt_portgroup -VDSwitch $vds
$vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $vmhost
Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-Null
 
$vswitch = Get-VirtualSwitch -VMHost $vmhost -Name vSwitch0
 
Write-Host "Removing vSwitch portgroup" $mgmt_portgroup
$mgmt_pg = Get-VirtualPortGroup -Name $mgmt_portgroup -VirtualSwitch $vswitch
Remove-VirtualPortGroup -VirtualPortGroup $mgmt_pg -confirm:$false
 
Write-Host "Removing vSwitch portgroup" $vmotion_portgroup
$vmotion_pg = Get-VirtualPortGroup -Name $vmotion_portgroup -VirtualSwitch $vswitch
Remove-VirtualPortGroup -VirtualPortGroup $vmotion_pg -confirm:$false
 
Write-Host "Removing vSwitch portgroup" $storage_portgroup
$storage_pg = Get-VirtualPortGroup -Name $storage_portgroup -VirtualSwitch $vswitch
Remove-VirtualPortGroup -VirtualPortGroup $storage_pg -confirm:$false
Write-Host "`n"
}
 
