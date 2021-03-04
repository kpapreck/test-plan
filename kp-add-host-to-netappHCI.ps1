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


Write-Host -ForegroundColor Blue "============================================================================================"
Write-Host -ForegroundColor Blue "Before starting have you verified all of the variables are correct?"
Write-Host -ForegroundColor Blue "  Cluster to add to NetApp HCI vCenter will be $newcluster in Datacenter $location"
Write-Host -ForegroundColor Blue "  ESXi host $esxi host will add $nic1 and $nic2 for a 2-cable setup"
Write-Host -ForegroundColor Blue "  This host will be added to: $hcivds and will add the following port groups"
Write-Host -ForegroundColor Blue "    vmk0: $mgmt_portgroup"
Write-Host -ForegroundColor Blue "    vmk1: $iscsiA"
Write-Host -ForegroundColor Blue "    vmk2: $iscsiB"
Write-Host -ForegroundColor Blue "    vmk3: $vmotion"
Write-Host -ForegroundColor Blue "============================================================================================"

[uint16]$Choice=1
While ($Choice -ne 0)
{
Write-Host -ForegroundColor Red "Step 1,2 and 3 are expected to be run sequentially. If you have already completed step 1 or step 2, you can start with step 3"
Write-Host -ForegroundColor Green "What would you like to do?"
Write-Host -ForegroundColor Green "1: Create new cluster named $newcluster in datacenter $location"
Write-Host -ForegroundColor Green "2: Add ESXi host to $newcluster and configure host networking to integrate into $hcivds"
Write-Host -ForegroundColor Green "3: Setup SolidFire connections to $newcluster and add additional datastores on SolidFire"
Write-Host -ForegroundColor Green "0: Exit"
[uint16]$Choice=Read-Host "Select the operation you would like to perform [0]"
switch($Choice)
{
   1 {
      # Create new vCenter Cluster
      Write-Host -ForegroundColor Blue "Adding $newcluster to vCenter"

      #matching NetApp HCI defaults: 
      #  HAEnabled, AddmissionControlEnabled, HAfailoverlevel2, 
      #  swap withVM, DRS fullyautomated, Default VM restart Medium,, isolation disabled
      
      New-Cluster -Name $newcluster -Location $location -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 2 -VMSwapfilepolicy "withVM" -HARestartPriority "Medium" -HAIsolationResponse "DoNothing" -DRSEnabled -DRSAutomationLevel "FullyAutomated"
     }

  2 {
      $vmhost = Read-Host "Enter FQDN or IP of ESXi host to add to $newcluster"
      # Add Host to vCenter Cluster defined above
      Write-Host -ForegroundColor Blue "Adding $vmhost to $newcluster"
      Add-VMhost $vmhost -Location $newcluster -User $esxihostuser -Password $esxihostpassword -Force

      #verify that the host has been added to $mycluster      
      $verify = Get-VMHost $vmhost | select connectionstate  -expandproperty ConnectionState
      If ($verify -ne "Connected"){
        Write-Host -ForegroundColor Blue "Host is not connected. Stopping script"
        break
      }
 
      # List all of the hosts you are adding to the cluster
      #multiple host example: $vmhost_array = @("host1","host2")
      # in order to use multiple host through array will need to change the format of the foreach statement below
      #$vmhost_array = @($vmhost)

      $vmhost_array = Get-VMHost $vmhost
      
      Write-Host -ForegroundColor Blue "$vmhost has been added to $mycluster. Starting network configuration and migration from VSS to VDS"
      #Add host and configure into NetApp HCI VDS
        foreach ($vmhost in $vmhost_array) {
	  Write-Host -ForegroundColor Blue "Adding $vmhost to $hcivds"
	  $vds | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null
	  Write-Host -ForegroundColor Blue "Adding $nic2 from $vmhost to $hcivds"

	  $Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic2
          Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

          #Migrate VMkernel interfaces to VDS

          # Management #
          #$mgmt_portgroup = "Management Network"
          Write-Host -ForegroundColor Blue "Migrating $mgmt_portgroup to $hcivds"
          $dvportgroup = Get-VDPortgroup -name $mgmt_portgroup -VDSwitch $vds
          $vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $vmhost
          Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-Null

          Write-Host  -ForegroundColor Blue "Removing vnic0 from vSwitch0"
          $vmhost |Get-VMHostNetworkAdapter -Name $nic1 |Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
          $Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic1
          Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

          Write-Host -ForegroundColor Blue "Adding $iscsiA Port Group"
          $ip1 = Read-Host "Enter iSCSI-A IP for $vmhost"
          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiA -virtualSwitch $hcivds -IP $ip1 -SubnetMask $iscsiSubnet -Mtu 9000 

          Write-Host -ForegroundColor Blue "Adding $iscsiB Port Group"
          $ip2 = Read-Host "Enter iSCSI-B IP for $vmhost"
          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiB -virtualSwitch $hcivds -IP $ip2 -SubnetMask $iscsiSubnet -Mtu 9000

          Write-Host -ForegroundColor Blue "Adding $vmotion Port Group"
          $ip3 = Read-Host "Enter vMotion IP for $vmhost"
          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $vmotion -virtualSwitch $hcivds -IP $ip3 -SubnetMask $vmotionSubnet -Mtu 9000 -VMotionEnabled $true

          Write-Host -ForegroundColor Blue "Removing vSwitch0 from $vmhost"
          Remove-VirtualSwitch -VirtualSwitch "vSwitch0" -Confirm:$false

          Write-Host -ForegroundColor Blue "Enable iSCSI on $vmhost"
          Get-VMHostStorage -VMHost $vmhost | Set-VMHostStorage -SoftwareIScsiEnabled $true
      
          # Bind NICs to HBA
          Write-Host -ForegroundColor Blue "Bind vmk1 and vmk2 to iSCSI Initiator"
          $HBANumber = Get-VMHostHba -VMHost $vmhost -Type iSCSI    | %{$_.Device}
          Write-Host -ForegroundColor Blue "Bind Port NIC to iSCSI <$vmhost> <$HBANumber>"
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
  3 {
      #Setup connections for the new host to NetApp SolidFire"
      Write-Host -ForegroundColor Blue "Items included in this section includes:"
      Write-Host -ForegroundColor Blue "  Creating new account called $newcluster"
      Write-Host -ForegroundColor Blue "  Creating # of volumes of X amount of size and specified QoS settings on SolidFire"
      Write-Host -ForegroundColor Blue "  Adding these volumes to NetApp-HCI acesss group (or a different one if changed)"
      Write-Host -ForegroundColor Blue "  Adding SolidFire SVIP to ESXi host(s) that reside within $newcluster"
      Write-Host -ForegroundColor Blue "  Creating VMware datastores on ESXi hosts based on the volumes created"
      Write-Host -ForegroundColor Blue "  Rescanning adapters to complete the setup"
      $continue = Read-Host "Do you want to continue with integrating these ESXi hosts with SolidFire?[y/n]"
      If ($continue -eq "y"){ 
        #This assumes that New-TenantOrCluster-NetAppHCI.ps1 resides in the same directory as this script
        #This script also assumes an active session to both vCenter and SolidFire

        . ./New-TenantOrCluster-NetAppHCI.ps1
        New-TenantOrCluster -Cluster $newcluster
      }
    } 
  default
    {
      $Choice=0
    }  
}
}  
