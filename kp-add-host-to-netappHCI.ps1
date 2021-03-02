$newcluster = "mycluster"
$location = "NetApp-HCI-Datacenter-01"
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
$esxihostuser = "root"
$esxihostpassword = "NetApp123!"

# fetch NetApp HCI VDS 01 information
$vds = Get-VDSwitch -Name $hcivds

# Create new vCenter Cluster
Write-Host "Adding $newcluster to vCenter"
New-Cluster -Name $newcluster -Location $location

#example with HA and DRS
#New-Cluster -Name $newcluster -Location $location -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 2 -VMSwapfilepolicy "InHostDatastore" -HARestartPriority "Low" -HAIsolationResponse "PowerOff" -DRSEnabled -DRSAutomationLevel 'Manual'

# Add Host to vCenter Cluster defined above
Write-Host "Adding $esxihost to $newcluster"
Add-VMhost $vmhost -Location $newcluster -User $esxihostuser -Password $esxihostpassword -Force


# List all of the hosts you are adding to the cluster
#multiple host example: $vmhost_array = @("host1","host2")
# in order to use multiple host through array will need to change the format of the foreach statement below
#$vmhost_array = @($esxihost)

$vmhost_array = Get-VMHost $esxihost

#Add host and configure into NetApp HCI VDS
foreach ($vmhost in $vmhost_array)
{
Write-Host "Adding $vmhost to $hcivds"
$vds | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null


Write-Host "Adding $nic2 from $vmhost to $hcivds"

$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic2
Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

#Migrate VMkernel interfaces to VDS

# Management #
$mgmt_portgroup = "Management Network"
Write-Host "Migrating $mgmt_portgroup to $hcivds"
$dvportgroup = Get-VDPortgroup -name $mgmt_portgroup -VDSwitch $vds
$vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $vmhost
Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-Null


Write-Host  -Object 'Removing vnic0 from vswitch'
$vmhost |Get-VMHostNetworkAdapter -Name $nic1 |Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
$Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic1
Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

Write-Host -Object 'Removing $switch from $vmhost'
Remove-VirtualSwitch -VirtualSwitch $switch -Confirm:$false

Write-Host "Adding $iscsiA Port Group"
$ip1 = Read-Host "Enter iSCSI-A IP for $vmhost"
New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiA -virtualSwitch $hcivds -IP $ip1 -SubnetMask $subnet -Mtu 9000 

Write-Host "Adding $iscsiB Port Group"
$ip2 = Read-Host "Enter iSCSI-B IP for $vmhost"
New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiB -virtualSwitch $hcivds -IP $ip2 -SubnetMask $subnet -Mtu 9000

Write-Host "Adding $vmotion Port Group"
$ip3 = Read-Host "Enter vMotion IP for $vmhost"
New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $vmotion -virtualSwitch $hcivds -IP $ip3 -SubnetMask $subnet -Mtu 9000 -VMotionEnabled $true

Write-Host "Enable iSCSI on $vmhost"
Get-VMHostStorage -VMHost $vmhost | Set-VMHostStorage -SoftwareIScsiEnabled $true





}
