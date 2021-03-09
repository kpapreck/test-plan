#       ======================================================================
#       Disclaimer: This script is written as best effort and provides no
#       warranty expressed or implied. Please contact the author(s) if you
#       have questions about this script before running or modifying
#       
#       Do not run this code in a production environment without first testing
#       ======================================================================

# 	This code will create a new cluster in a NetApp HCI vCenter, add the host(s) to the cluster and integrate them into the existing NetApp HCI VDS switch


###################################################################################################
##### Variables used in script
###################################################################################################
. ./scale-vars.ps1
#This assumes that scale-vars.ps1 and New-TenantOrCluster-NetAppHCI.ps1 reside in the same directory as this script

###Description of Variables###
# newcluster = name of the new cluster being created
# location = the datacenter within NetApp HCI to add the cluster
# hcivds = the existing VDS switch that you are looking to add the new hosts into
# nic1 and nic2 are the vmnics of the new host adding to the cluster
# Uplinks are the uplinks to add to for a 2-cable setup
# switch = VSS switch created by default before adding 
# iscsiA/iscsiB/vmotion = vmk port group names from existing VDS to integrate into the new host
# iscsiSubnet = subnet used for iscsiA/iscsiB
# vmotionSubnet = subnet used for vmotion



###################################################################################################
##### Connect to vCenter and SolidFire
###################################################################################################

#$viserver = Read-Host "Enter vCenter FQDN or IP to initiate connection"
#$vcred = Get-Credential -Message "Enter vCenter administrator credentials for [$viserver]"
#$vcred | connect-viserver -server $viserver

#$sfconnect = Read-Host "Enter SolidFire MVIP for connection to storage"
#$scred = Get-Credential -Message "Enter SolidFire administrator credentials for [$sfconnect]"
#$scred | connect-sfcluster -target $sfconnect


# SolidFire connection to add ESXi host(s) into:
#$sf = Get-SFClusterInfo | select Name -ExpandProperty Name

# grab VDS info
#$vds = Get-VDSwitch -Name $hcivds

Write-Host -ForegroundColor Blue "==============================================================================================================================="
Write-Host -ForegroundColor Blue "Before starting have you verified all of the variables are correct?"
Write-Host -ForegroundColor Blue "  Cluster to add to NetApp HCI vCenter [$viserver] will be [$newcluster] in Datacenter [$location]"
Write-Host -ForegroundColor Blue "  ESXi host(s) host will be configured with 2 x 10/25G links for a 2-cable setup"
Write-Host -ForegroundColor Blue "    Physical 10/25G connections to add will have all three required VLANs and will use: [$nic1var] and [$nic2var]"
Write-Host -ForegroundColor Blue "    These ports will be added using the following uplinks: [$uplink1] and [$uplink2] migrating from the default vSS [$switch]"
Write-Host -ForegroundColor Blue "  ESXi host(s) will be added to: [$hcivds] and will add the following port groups:"
Write-Host -ForegroundColor Blue "    vmk0: [$mgmt_portgroup_var]"
Write-Host -ForegroundColor Blue "    vmk1: [$iscsiA]"
Write-Host -ForegroundColor Blue "    vmk2: [$iscsiB]"
Write-Host -ForegroundColor Blue "    vmk3: [$vmotion]"
Write-Host -ForegroundColor Blue "  The ESXi hosts within [$newcluster] will then setup connections and integrate into NetApp SolidFire [$sfconnect]"
Write-Host -ForegroundColor Blue "If any of this is incorrect, exit and edit scale-vars.ps1 file"
Write-Host -ForegroundColor Blue "==============================================================================================================================="



[uint16]$Choice=1
While ($Choice -ne 0)
{
Write-Host -ForegroundColor Red "Step 1,3 and 4 are expected to be run sequentially. If you have already completed step 1 or step 2, you can start with step 3"
Write-Host -ForegroundColor Green "What would you like to do?"
Write-Host -ForegroundColor Green "1: Connect to vCenter [$viserver] and SolidFire [$sfconnect]"
Write-Host -ForegroundColor Green "2: Verify connections to vCenter and SolidFire"
Write-Host -ForegroundColor Green "3: Create new cluster named [$newcluster] in datacenter [$location] within vCenter connection from step 1"
Write-Host -ForegroundColor Green "4: Add ESXi host to $newcluster and configure host networking to integrate into [$hcivds]"
Write-Host -ForegroundColor Green "5: Setup SolidFire connections to [$newcluster] and add additional datastores on SolidFire from step 1"
Write-Host -ForegroundColor Green "6: Disconnect from vCenter [$viserver] and SolidFire [$sfconnect]"
Write-Host -ForegroundColor Green "7: Custom - Enter code where you needed to quit if you need to restart at any process"
Write-Host -ForegroundColor Green "0: Exit"
[uint16]$Choice=Read-Host "Select the operation you would like to perform [0]"
switch($Choice)
{
   1 {
      ###################################################################################################
      ##### 1: Connect to vCenter [$viserver] and SolidFire [$sfconnect]
      ###################################################################################################
     
      #$viserver = Read-Host "Enter vCenter FQDN or IP to initiate connection"
      $vcred = Get-Credential -Message "Enter vCenter administrator credentials for [$viserver]"
      $vcred | connect-viserver -server $viserver

      #$sfconnect = Read-Host "Enter SolidFire MVIP for connection to storage"
      $scred = Get-Credential -Message "Enter SolidFire administrator credentials for [$sfconnect]"
      $scred | connect-sfcluster -target $sfconnect


      # SolidFire connection to add ESXi host(s) into:
      #$sf = Get-SFClusterInfo | select Name -ExpandProperty Name

      # grab VDS info
      #$vds = Get-VDSwitch -Name $hcivds


     }
   2 {
     $sf = Get-SFClusterInfo | select Name -ExpandProperty Name
     Write-Host -ForegroundColor Blue "You are connected to SolidFire Cluster [$sf]"
     $vi = $global:DefaultVIServer
     Write-Host -ForegroundColor Blue "You are connected to vCenter Cluster [$vi]"
     }



   3 {
      ###################################################################################################
      ##### Create new cluster named [$newcluster] in datacenter [$location]
      ###################################################################################################

      # Create new vCenter Cluster
      Write-Host -ForegroundColor Blue "Adding $newcluster to vCenter"

      #matching NetApp HCI defaults: 
      #  HAEnabled, AddmissionControlEnabled, HAfailoverlevel2, 
      #  swap withVM, DRS fullyautomated, Default VM restart Medium,, isolation disabled
      
      New-Cluster -Name $newcluster -Location $location -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 2 -VMSwapfilepolicy "withVM" -HARestartPriority "Medium" -HAIsolationResponse "DoNothing" -DRSEnabled -DRSAutomationLevel "FullyAutomated"
     }

  4 {
      ###################################################################################################
      ##### Add ESXi host to $newcluster and configure host networking to integrate into [$hcivds]
      ###################################################################################################
      
       # grab VDS info
      $vds = Get-VDSwitch -Name $hcivds

      #### Start of adding host section ####
      $vmhost = Read-Host "Enter FQDN or IP of ESXi host to add to $newcluster if different from [$s_vmhost]"
         if([string]::IsNullOrWhiteSpace($vmhost))
          {
            $vmhost=$s_vmhost
          }
      
      
      # Add Host to vCenter Cluster defined above
      Write-Host -ForegroundColor Blue "Adding $vmhost to $newcluster"
      $rcred = Get-Credential -Message "Enter credentials using user [root] and its password"
      Add-VMhost $vmhost -Location $newcluster -Credential $rcred -Force

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
      
      #### Start of Network Configuration of ESXi Host ####
      
      Write-Host -ForegroundColor Blue "[$vmhost] has been added to [$mycluster]. Starting network configuration and migration from VSS to VDS"
      
      #verifying physical nics are the correct vmnic numbers
      $nic1 = Read-Host "If this is the correct 1st 10/25G connected physical nic for the new ESXi host(s), continue, otherwise enter value [$nic1var]"
        if([string]::IsNullOrWhiteSpace($nic1))
          {
            $nic1=$nic1var
          }
      $nic2 = Read-Host "If this is the correct 2nd 10/25G connected physical nic for the new ESXi host(s), continue, otherwise enter value [$nic2var]"
        if([string]::IsNullOrWhiteSpace($nic2))
        {
          $nic2=$nic2var
        }

      $mgmt_portgroup = Read-Host "Enter new value if destination Management Port Group on VDS is different from [$mgmt_portgroup_var]"
        if([string]::IsNullOrWhiteSpace($mgmt_portgroup))
        {
          $mgmt_portgroup=$mgmt_portgroup_var
        }

      #Add host and configure into NetApp HCI VDS
        foreach ($vmhost in $vmhost_array) {
	  Write-Host -ForegroundColor Blue "Adding [$vmhost] to [$hcivds]"
	  $vds | Add-VDSwitchVMHost -VMHost $vmhost | Out-Null
	  Write-Host -ForegroundColor Blue "Adding [$nic2] from [$vmhost] to [$hcivds]"
	  $Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic2
          Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

          #Migrate VMkernel interfaces to VDS

          # Management #
          Write-Host -ForegroundColor Blue "Migrating management to [$mgmt_portgroup] on [$hcivds]"
          $dvportgroup = Get-VDPortgroup -name $mgmt_portgroup -VDSwitch $vds
          $vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $vmhost
          Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -confirm:$false | Out-Null

          Write-Host  -ForegroundColor Blue "Removing vnic0 from vSwitch0"
          $vmhost |Get-VMHostNetworkAdapter -Name $nic1 |Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
          $Phnic = $vmhost |Get-VMHostNetworkAdapter -Physical -Name $nic1
          Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $vds -VMHostPhysicalNic $Phnic -Confirm:$false

          Write-Host -ForegroundColor Blue "Adding [$iscsiA] Port Group"
          $iscsiSubnet = Read-Host "Enter new value for iSCSI subnet if incorrect [$iscsiSubnet_var]"
            if([string]::IsNullOrWhiteSpace($iscsiSubnet))
              {
                $iscsiSubnet=$iscsiSubnet_var
              }


          $ip1 = Read-Host "Enter iSCSI-A IP for $vmhost if different from [$s_ip1]"
            if([string]::IsNullOrWhiteSpace($ip1))
              {
                $ip1=$s_ip1
              }

          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiA -virtualSwitch $hcivds -IP $ip1 -SubnetMask $iscsiSubnet -Mtu 9000 

          Write-Host -ForegroundColor Blue "Adding [$iscsiB] Port Group"
          $ip2 = Read-Host "Enter iSCSI-B IP for $vmhost if different from [$s_ip2]"
            if([string]::IsNullOrWhiteSpace($ip2))
              {
                $ip2=$s_ip2
              }

          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $iscsiB -virtualSwitch $hcivds -IP $ip2 -SubnetMask $iscsiSubnet -Mtu 9000

          Write-Host -ForegroundColor Blue "Adding [$vmotion] Port Group"
          $vmotionSubnet = Read-Host "Enter new value for vMotion subnet if incorrect [$vmotionSubnet_var]"
            if([string]::IsNullOrWhiteSpace($vmotionSubnet))
              {
                $vmotionSubnet=$vmotionSubnet_var
              }
          $ip3 = Read-Host "Enter vMotion IP for $vmhost if different from [$s_ip3]"
            if([string]::IsNullOrWhiteSpace($ip3))
              {
                $ip3=$s_ip3
              }

          New-VMHostNetworkAdapter -VMHost $vmhost -PortGroup $vmotion -virtualSwitch $hcivds -IP $ip3 -SubnetMask $vmotionSubnet -Mtu 9000 -VMotionEnabled $true

          Write-Host -ForegroundColor Blue "Removing vSwitch0 from [$vmhost]"
          Remove-VirtualSwitch -VirtualSwitch "vSwitch0" -Confirm:$false

          Write-Host -ForegroundColor Blue "Enable iSCSI on [$vmhost]"
          Get-VMHostStorage -VMHost $vmhost | Set-VMHostStorage -SoftwareIScsiEnabled $true
      
          # Bind NICs to HBA
          Write-Host -ForegroundColor Blue "Bind vmk1 and vmk2 to iSCSI Initiator"
          $HBANumber = Get-VMHostHba -VMHost $vmhost -Type iSCSI    | %{$_.Device}
          Write-Host -ForegroundColor Blue "Bind Port NIC to iSCSI [$vmhost] [$HBANumber]"
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
  5 {
      ###################################################################################################
      ##### Setup SolidFire connections to [$newcluster] and add additional datastores on SolidFire [$sf]
      ###################################################################################################
      
      # SolidFire connection to add ESXi host(s) into:
      $sf = Get-SFClusterInfo | select Name -ExpandProperty Name

      #Setup connections for the new host to NetApp SolidFire [$sf]"
      Write-Host -ForegroundColor Blue "Items included in this section includes:"
      Write-Host -ForegroundColor Blue "  Creating new account called [$newcluster]"
      Write-Host -ForegroundColor Blue "  Creating # of volumes of X size and specified QoS settings on SolidFire"
      Write-Host -ForegroundColor Blue "  Adding these volumes to NetApp-HCI access group (or a different one if changed)"
      Write-Host -ForegroundColor Blue "  Adding SolidFire SVIP to ESXi host(s) that reside within $newcluster"
      Write-Host -ForegroundColor Blue "  Creating VMware datastores on ESXi hosts based on the volumes created"
      Write-Host -ForegroundColor Blue "  Rescanning adapters to complete the setup"
      $continue = Read-Host "Do you want to continue with integrating these ESXi hosts with SolidFire?[y/n]"
      If ($continue -eq "y"){ 
        #This assumes that New-TenantOrCluster-NetAppHCI.ps1 resides in the same directory as this script
        #This script also assumes an active session to both vCenter and SolidFire
        Write-Host -ForegroundColor Blue "Datastores to add: [$qtyvol] of size [$sizeGB] using QoS Min [$min], Max [$max] and Burst [$burst] IOPs"
	$change = Read-Host "Would you like to manually change any of these values, y/n [n]" 
        . ./New-TenantOrCluster-NetAppHCI.ps1
        If ($change -eq "y") {
          New-TenantOrCluster -Cluster $newcluster
        }
        else {
          New-TenantOrCluster -Cluster $newcluster -qtyvol $qtyvol -sizeGB $sizeGB -min $min -max $max -burst $burst
        }
      }
    }
  6 {
      ###################################################################################################
      ##### Disconnect from vCenter and SolidFire
      ###################################################################################################

      disconnect-viserver -server $viserver
      disconnect-sfcluster -target $sfconnect
      
    }
  7 {
     ###################################################################################################
     ##### Custom Section if needed to start/stop at a specific spot. Copy code into #5
     ###################################################################################################

    } 
  default
    {
      $Choice=0
    }  
}
}  
