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
