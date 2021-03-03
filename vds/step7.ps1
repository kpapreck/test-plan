$hcivds = "NetApp HCI VDS 01"
$vds = Get-VDSwitch -Name $hcivds
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
$newcluster = "mycluster"
$vds = Get-VDSwitch -Name $hcivds
#THIS LINE WAS JUST REPLACED $vmhost_array = Get-VMHost $esxihost
#multiple host example: $vmhost_array = @("host1","host2")
$vmhost_array = @($esxihost)

foreach ($vmhost in $vmhost_array)
{

#$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic2
#Write-Host  -Object "Adding vmnic (redundant) to $vds"
#Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

#Migrate VMkernel interfaces to VDS

# Management #
#$mgmt_portgroup = "Management Network"
#Write-Host "Migrating" $mgmt_portgroup "to" $hcivds
#$dvportgroup = Get-VDPortgroup -name $mgmt_portgroup -VDSwitch $vds
#$vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $vmhost
#Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-Null



#Write-Host  -Object 'Removing vnic from vswitch'
#$vmhost |Get-VMHostNetworkAdapter -Name $nic1 |Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
#$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic1
#Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

#Remove-VirtualSwitch -VirtualSwitch $switch -Confirm:$false

#Write-Host "Adding $iscsiA Port Group"
#$ip1 = Read-Host "Enter iSCSI-A IP for $vmhost"
#New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiA -virtualSwitch $hcivds -IP $ip1 -SubnetMask $subnet -Mtu 9000 

#Write-Host "Adding $iscsiB Port Group"
#$ip2 = Read-Host "Enter iSCSI-B IP for $vmhost"
#New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiB -virtualSwitch $hcivds -IP $ip2 -SubnetMask $subnet -Mtu 9000

#Write-Host "Adding $vmotion Port Group"
#$ip3 = Read-Host "Enter vMotion IP for $vmhost"
#New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $vmotion -virtualSwitch $hcivds -IP $ip3 -SubnetMask $subnet -Mtu 9000 -VMotionEnabled $true

#Write-Host "Enable iSCSI on $vmhost"
#Get-VMHostStorage -VMHost $vmhost | Set-VMHostStorage -SoftwareIScsiEnabled $true

# Bind NICs to HBA
$HBANumber = Get-VMHostHba -VMHost $vmhost -Type iSCSI    | %{$_.Device}
Write-Host "Bind Port NIC to iSCSI <$vmhost> <$HBANumber>" -ForegroundColor Green
$esxcli = Get-EsxCli -V2 -VMhost $vmhost
$esxcli.iscsi.networkportal.add.CreateArgs()
$iScsi = @{
  force = $false
  nic = "vmk1"
  adapter = $HBANumber
}
$esxcli.iscsi.networkportal.add.Invoke($iScsi)
$iScsi = @{
  force = $false
  nic = "vmk2"
  adapter = $HBANumber
}
$esxcli.iscsi.networkportal.add.Invoke($iScsi)
Get-Cluster -Name $newcluster | Get-VMHost | Get-VMHostStorage -RescanAllHba



}
