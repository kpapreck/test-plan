
# ESXi hosts to migrate from VSS to VDS 
$VDSw = "NetApp HCI VDS 01"
$vds = Get-VDSwitch -Name $VDSw
$nic1 = "vmnic0"
$nic2 = "vmnic1"
$esxihost = "winf-evo3-blade4.ntaplab.com"
$uplink1 = "Uplink 1"
$uplink2 = "Uplink 2"
$switch = "vSwitch0"
$vmhost = $esxihost


$vmhost_array = Get-VMHost $esxihost


# get existing VDswitch 


$vds = Get-VDSwitch -Name $VDSw 


foreach ($vmhost in $vmhost_array)


{ 


# Add ESXi hosts to VDS 


#Write-Host  -Object "Adding $vmhost to $vds"


#$null = $vds |Add-VDSwitchVMHost -VMHost $vmhost 


# Migrate pNICs to VDS 


Write-Host  -Object 'Fetching First vnic connected to vswitch' 


$vmhostNetworkAdapter = Get-VMHost $vmhost |Get-VirtualSwitch -Name $switch | Select-Object -ExpandProperty Nic | Select-Object -First 1 


Write-Host  -Object 'Removing vnic from vswitch' 


$vmhost |Get-VMHostNetworkAdapter -Name $vmhostNetworkAdapter |Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false 


Write-Host  -Object 'Fetching removed vnic into a varible' 


$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $vmhostNetworkAdapter 


Write-Host  -Object "Adding vmnic (redundant) to $vds" 


Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false 


# Migrate VMs from VSS to VDS 


Write-Host  -Object 'Fetching virtualPortgroup info from vswitch' 


$vssPG1 = $vmhost |Get-VirtualPortGroup -VirtualSwitch $switch 


Write-Host  -Object 'migrating vms from VSS to VDS' 


foreach($vssPG in $vssPG1)


 { 


$dvsPG = $vds |Get-VDPortgroup |Where-Object  -FilterScript {$_.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId -eq $vssPG.VlanId} 


$vmhost |Get-VM |Get-NetworkAdapter |Where-Object  -FilterScript {$_.NetworkName -eq $vssPG.Name} | Set-NetworkAdapter -NetworkName $dvsPG.Name -Confirm:$false


}


}



