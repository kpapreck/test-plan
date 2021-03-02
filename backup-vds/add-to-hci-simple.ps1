$newcluster = "mycluster"
$location = "NetApp-HCI-Datacenter-01"
$VDSw = "NetApp HCI VDS 01"
#$vcenter = "svl-hci-vc01.ntaplab.com"
$vcenter = "10.45.85.185"
$esxihost = "winf-evo3-blade4.ntaplab.com"
$esxihostuser = "root"
$esxihostpassword = "NetApp123!"
$nic1 = "vmnic0"
$nic2 = "vmnic1"
$mgmt_portgroup = "Management 89"

#reference #2 - https://www.dutchvblog.com/powercli/useful-powercli-scripts/

#set PowerCLI options
#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

#create compute cluster 
#note - this is for a new cluster without EVCMode/DRS/HA
New-Cluster -Name $newcluster -Location $location 

#example with HA and DRS
#New-Cluster -Name $newcluster -Location $location -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 2 -VMSwapfilepolicy "InHostDatastore" -HARestartPriority "Low" -HAIsolationResponse "PowerOff" -DRSEnabled -DRSAutomationLevel 'Manual'

#add host to the new compute cluster
Add-VMhost $esxihost -Location $newcluster -User $esxihostuser -Password $esxihostpassword -Force

#VDS tips: https://nerdblurt.com/powercli-add-cluster-hosts-to-existing-virtual-distributed-switch/

$ClHost = Get-Cluster $newcluster | Get-VMHost


# Add each host in the Cluster to the Distributed Switch
ForEach ($VMHost in $ClHost)
{
# Add hosts to the VDS
Get-VDSwitch -Name $VDSw | Add-VDSwitchVMHost -VMHost $VMHost
}

#Get VDSwitch object
$vds = Get-VDSwitch -Name $VDSw

# Migrate first 2 nics to VDS
Write-Host "Adding $nic1 and $nic2 to" $vds_name
  $vmhostNetworkAdapter = Get-VMHost $_.hostname | Get-VMHostNetworkAdapter -Physical -Name $nic1
  $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$true
  $vmhostNetworkAdapter = Get-VMHost $_.hostname | Get-VMHostNetworkAdapter -Physical -Name $nic2
  $vds | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$true

# Migrate Management VMkernel interface to VDS
$dvportgroup = Get-VDPortGroup -name $mgmt_portgroup -VDSwitch $vds
$vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $VMHost

Read-Host "did the uplinks get added or do I need to continue"

# Collect vmnics to add as uplinks into an array
$VMNICS = @()
do {
$input = (Read-Host "Enter the VMNIC name and press enter (just enter to end)")
if ($input -ne '') {$VMNICS += $input}
}
until ($input -eq '')


# Disconnect from Cluster as commands to add uplinks are per host
#Disconnect-VIServer $vcenter -Confirm:$false

# Add uplinks for each host to VDS
ForEach ($VMHost in $ClHost)
{
# Get Host Password if not typed above
# $esxihostpassword = Read-Host "Enter the $UserAcct password for $VMHost.Name"

# Connect to host, host PW in quotes to account for special characters
Connect-VIServer -Server $VMHost.Name -User $esxihostuser -Password $esxihostpassword | Out-Null

# Add uplinks for the host to the VDS
ForEach ($VMNIC in $VMNICS)
{
$vmhostNetworkAdapter = Get-VMHost $VMHost | Get-VMHostNetworkAdapter -Physical -Name $VMNIC
Get-VDSwitch $VDSw | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $vmhostNetworkAdapter -Confirm:$false
}


# Disconnect from host
Disconnect-VIServer $VMHost.name -Confirm:$false
}


