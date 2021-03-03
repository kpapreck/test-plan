#       ======================================================================
#       Disclaimer: This script is written as best effort and provides no
#       warranty expressed or implied. Please contact the author(s) if you
#       have questions about this script before running or modifying
#       
#       Do not run this code in a production environment without first testing
#       ======================================================================

# 	This code will create a new cluster in a NetApp HCI vCenter, add the host(s) to the cluster and integrate them into the existing NetApp HCI VDS switch

# DESCRIPTION OF VARS
# newcluster = name of the new cluster being created
# location = the datacenter within NetApp HCI to add the cluster
# hcivds = the existing VDS switch that you are looking to add the new hosts into
# nic1 and nic2 are the vmnics of the new host adding to the cluster
# Uplinks are the uplinks to add to for a 2-cable setup
# switch = VSS switch created by default before adding 
# iscsiA/iscsiB/vmotion = vmk port group names from existing VDS to integrate into the new host
# iscsiSubnet = subnet used for iscsiA/iscsiB
# vmotionSubnet = subnet used for vmotion
# esxihostuser/esxihostpassword are used for the esxi host credentials. These can be moved to a cred file later


# VMware Cluster Information
$newcluster = "mycluster"
$location = "NetApp-HCI-Datacenter-01"

# Existing VDS information
$hcivds = "NetApp HCI VDS 01"
$vds = Get-VDSwitch -Name $hcivds

# Host network properties
# need to fetch vmnic numbers from DCUI under Network Adapters

$nic1 = "vmnic0"
$nic2 = "vmnic1"
$uplink1 = "Uplink 1"
$uplink2 = "Uplink 2"
$switch = "vSwitch0"
$iscsiA = "NetApp HCI VDS 01-iSCSI-A"
$iscsiB = "NetApp HCI VDS 01-iSCSI-B"
$vmotion = "NetApp HCI VDS 01-vMotion"
$iscsiSubnet = "255.255.255.0"
$vmotionSubnet = "255.255.255.0"
$mgmt_portgroup = "Management Network 89"

#uncomment the next line to use the default NetApp HCI management network
#$mgmt_portgroup = "NetApp HCI VDS 01-Management Network"

# VM host properties
$vmhost = "winf-evo3-blade4.ntaplab.com"
$esxihostuser = "root"
$esxihostpassword = "NetApp123!"

# fetch NetApp HCI VDS 01 information
#$vds = Get-VDSwitch -Name $hcivds

[uint16]$Choice=1
While ($Choice -ne 0)
{
Write-Host -ForegroundColor Blue "Before starting have you verified all of the variables are correct?"
Write-Host -ForegroundColor Blue "  Cluster to add to NetApp HCI vCenter will be $newcluster in Datacenter $location"
Write-Host -ForegroundColor Blue "  ESXi host $esxi host will add $nic1 and $nic2 for a 2-cable setup"
Write-Host -ForegroundColor Blue "  These hosts will then be added to the following VDS switch: $hcivds and will add the following port groups Management, $iscsiA, $iscsiB, $vmotion"

Write-Host -ForegroundColor Red "Step 1,2 and 3 are expected to be run sequentially. If you have already completed step 1 or step 2, you can start with step 3"
Write-Host -ForegroundColor Green "What would you like to do?"
Write-Host -ForegroundColor Green "1: Create new cluster named $newcluster in datacenter $location"
Write-Host -ForegroundColor Green "2: Add $vmhost to $newcluster"
Write-Host -ForegroundColor Green "3: Configure $vmhost networking to integrate into $hcivds"
Write-Host -ForegroundColor Green "4: Re-scan all adapters on hosts in $newcluster to display the portbinding information"
Write-Host -ForegroundColor Green "0: Exit"
[uint16]$Choice=Read-Host "Select the operation you would like to perform [0]"
switch($Choice)
{
   1 {
      # Create new vCenter Cluster
      Write-Host "Adding $newcluster to vCenter"
      #New-Cluster -Name $newcluster -Location $location

      #example with HA and DRS
      #netapp HCI defaults are HAEnabled, AdmissionControlEnabled, HAfailoverlevel2 swap withVM, DRS fullyautomated, Default VM restart Medium,, isolation disabled
      New-Cluster -Name $newcluster -Location $location -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 2 -VMSwapfilepolicy "withVM" -HARestartPriority "Medium" -HAIsolationResponse "DoNothing" -DRSEnabled -DRSAutomationLevel "FullyAutomated"
     }

  2 {
      # Add Host to vCenter Cluster defined above
      Write-Host "Adding $vmhost to $newcluster"
      Add-VMhost $vmhost -Location $newcluster -User $esxihostuser -Password $esxihostpassword -Force


      # List all of the hosts you are adding to the cluster
      #multiple host example: $vmhost_array = @("host1","host2")
      # in order to use multiple host through array will need to change the format of the foreach statement below
      #$vmhost_array = @($vmhost)

      $vmhost_array = Get-VMHost $vmhost
    }
  
  3 {
      #Add host and configure into NetApp HCI VDS
        foreach ($vmhost in $vmhost_array) {
	  Write-Host "Adding $vmhost to $hcivds"
	  $vds | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null
	  Write-Host "Adding $nic2 from $vmhost to $hcivds"

	  $Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic2
          Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

          #Migrate VMkernel interfaces to VDS

          # Management #
          #$mgmt_portgroup = "Management Network"
          Write-Host "Migrating $mgmt_portgroup to $hcivds"
          $dvportgroup = Get-VDPortgroup -name $mgmt_portgroup -VDSwitch $vds
          $vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $vmhost
          Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-Null

          Write-Host  -Object 'Removing vnic0 from vswitch'
          $vmhost |Get-VMHostNetworkAdapter -Name $nic1 |Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
          $Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic1
          Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

          Write-Host "Adding $iscsiA Port Group"
          $ip1 = Read-Host "Enter iSCSI-A IP for $vmhost"
          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiA -virtualSwitch $hcivds -IP $ip1 -SubnetMask $iscsiSubnet -Mtu 9000 

          Write-Host "Adding $iscsiB Port Group"
          $ip2 = Read-Host "Enter iSCSI-B IP for $vmhost"
          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiB -virtualSwitch $hcivds -IP $ip2 -SubnetMask $iscsiSubnet -Mtu 9000

          Write-Host "Adding $vmotion Port Group"
          $ip3 = Read-Host "Enter vMotion IP for $vmhost"
          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $vmotion -virtualSwitch $hcivds -IP $ip3 -SubnetMask $vmotionSubnet -Mtu 9000 -VMotionEnabled $true

          Write-Host "Removing vSwitch0 from $vmhost"
          Remove-VirtualSwitch -VirtualSwitch "vSwitch0" -Confirm:$false

          Write-Host "Enable iSCSI on $vmhost"
          Get-VMHostStorage -VMHost $vmhost | Set-VMHostStorage -SoftwareIScsiEnabled $true
      
          # Bind NICs to HBA
          Write-Host "Bind vmk1 and vmk2 to iSCSI Initiator"
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
          
      }
    }
  4 {
      #issue rescan of all HBAs on $newcluster"
      Write-Host "Rescan All HBAs on $newcluster"
      Get-Cluster -Name $newcluster | Get-VMHost | Get-VMHostStorage -RescanAllHba
    } 
  default
    {
      $Choice=0
    }  
}
}  
