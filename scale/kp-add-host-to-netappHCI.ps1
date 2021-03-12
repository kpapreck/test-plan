#       ======================================================================
#       Disclaimer: This script is written as best effort and provides no
#       warranty expressed or implied. Please contact the author(s) if you
#       have questions about this script before running or modifying
#
#       Do not run this code in a production environment without first testing
#       ======================================================================

# 	This code will create a new cluster in a NetApp HCI vCenter, add the host(s) to the cluster and integrate them into the existing NetApp HCI VDS switch


###################################################################################################
##### Variables used in script are located within scale-vars.ps1
###################################################################################################
. ./scale-vars.ps1
#This assumes that scale-vars.ps1 and New-TenantOrCluster-NetAppHCI.ps1 reside in the same directory as this script




###################################################################################################
##### Introduction
###################################################################################################

#Write-Host -ForegroundColor Blue "==============================================================================================================================="
#Write-Host -ForegroundColor Blue "Before starting have you verified all of the variables are correct in scale-vars.ps1?"
#Write-Host -ForegroundColor Blue "SolidFire Cluster: [$sfconnect]"
#Write-Host -ForegroundColor Blue "vCenter: [$viserver]"
#Write-Host -ForegroundColor Blue "vCenter datacenter: [$location]"
#Write-Host -ForegroundColor Blue "vCenter cluster: [$newcluster]"
#Write-Host -ForegroundColor Blue "vCenter switch: [$hcivds]"
#Write-Host -ForegroundColor Blue "  Uplink1: [$Uplink1]"
#Write-Host -ForegroundColor Blue "  Uplink2: [$Uplink2]"
#Write-Host -ForegroundColor Blue "  vmk0: [$mgmt_portgroup_var]"
#Write-Host -ForegroundColor Blue "  vmk1: [$iscsiA]"
#Write-Host -ForegroundColor Blue "  vmk2: [$iscsiB]"
#Write-Host -ForegroundColor Blue "  vmk3: [$vmotion]"
#Write-Host -ForegroundColor Blue "ESXi host to add: [$s_vmhost]"
#Write-Host -ForegroundColor Blue "  Physical NIC 1 to use: [$nic1var]"
#Write-Host -ForegroundColor Blue "  Physical NIC 2 to use: [$nic2var]"
#Write-Host -ForegroundColor Blue "  iSCSI A IP address: [$s_ip1]"
#Write-Host -ForegroundColor Blue "  iSCSI B IP address: [$s_ip2]"
#Write-Host -ForegroundColor Blue "  iSCSI subnet: [$iscsiSubnet_var]"
#Write-Host -ForegroundColor Blue "  vMotion IP address: [$s_ip3]"
#Write-Host -ForegroundColor Blue "  vMotion subnet: [$vmotionSubnet_var]"
#Write-Host -ForegroundColor Blue "If any of this is incorrect, exit and edit scale-vars.ps1 file"
#Write-Host -ForegroundColor Blue "==============================================================================================================================="

[uint16]$Choice=1
While ($Choice -ne 0)
{
#Write-Host -ForegroundColor Red "Step 1,3 and 4 are expected to be run sequentially. If you have already completed step 1 or step 2, you can start with step 3"
Write-Host -ForegroundColor Green "What would you like to do?"
Write-Host -ForegroundColor Green "1: Connect or verify connection to vCenter and SolidFire"
Write-Host -ForegroundColor Green "2: Create new vCenter objects (datacenter, cluster, distributed switch)"
Write-Host -ForegroundColor Green "3: Add ESXi host to $newcluster and configure host networking to integrate into either [$hcivds] or [$newvds]"
Write-Host -ForegroundColor Green "4: Setup SolidFire connections to [$newcluster] and add additional datastores on SolidFire from step 1"
Write-Host -ForegroundColor Green "5: Disconnect from vCenter and SolidFire"
Write-Host -ForegroundColor Green "0: Exit"

#Write-Host -ForegroundColor Green "6: Create new Datacenter/Cluster/VDS switch matching setup of NetApp HCI created via NDE"
#Write-Host -ForegroundColor Green "8: Custom - Enter code where you needed to quit if you need to restart at any process"

[uint16]$Choice=Read-Host "Select the operation you would like to perform [0]"
switch($Choice)
{
   1 {
      ###################################################################################################
      ##### 1: Connect to vCenter [$viserver] and SolidFire [$sfconnect] or verify connections
      ###################################################################################################
      $change = Read-Host "Create new connection to vCenter and SolidFire? y/n [y]"
      if([string]::IsNullOrWhiteSpace($change))
       {
         $change = "y"
       }
      If ($change -eq "y") {
        $viservercheck = Read-Host "Enter vCenter FQDN or IP to initiate connection if different from [$viserver]"
        if(!([string]::IsNullOrWhiteSpace($viservercheck)))
        {
          $viserver = $viservercheck
        }

        $vcred = Get-Credential -Message "Enter vCenter administrator credentials for [$viserver]"
        $vcred | connect-viserver -server $viserver


        $sfconnectcheck = Read-Host "Enter SolidFire MVIP for connection to storage if different from [$sfconnect]"
        if(!([string]::IsNullOrWhiteSpace($sfconnectcheck)))
        {
          $sfconnect = $sfconnectcheck
        }

        $scred = Get-Credential -Message "Enter SolidFire administrator credentials for [$sfconnect]"
        $scred | connect-sfcluster -target $sfconnect
      }

      #verify connections
      $sf = Get-SFClusterInfo | select Name -ExpandProperty Name
      Write-Host -ForegroundColor Blue "You are connected to SolidFire Cluster [$sf]"
      $vi = $global:DefaultVIServer
      Write-Host -ForegroundColor Blue "You are connected to vCenter Cluster [$vi]"


     }


   2 {
      ###################################################################################################
      ##### Create new vCenter objects (datacenter, cluster, distributed switch)
      ###################################################################################################
      Write-Host -ForegroundColor Blue "Current variables for this section include"
      Write-Host -ForegroundColor Blue "  vCenter: [$viserver]"
      Write-Host -ForegroundColor Blue "  vCenter datacenter: [$location]"
      Write-Host -ForegroundColor Blue "  vCenter cluster: [$newcluster]"

      $check = Read-Host "Do you need to quit to change values in scale-vars.ps1? y/n [n]"
      if ($check -eq "y")
      {
        break;
      }

      $check = Read-Host "Does datacenter location [$location] exist in vCenter? [n]"
      If ([string]::IsNullOrWhiteSpace($check) -Or $check -eq "n")
      {
         Write-Host -ForegroundColor Blue "Adding $location to vCenter"
         $Datacenter =  New-Datacenter -location (Get-Folder -NoRecursion) -Name $location
      }


      $check = Read-Host "Does vCenter cluster [$newcluster] already exist in vCenter? y/n [n]"
      if([string]::IsNullOrWhiteSpace($check) -Or $check -eq "n")
      {
        # Create new vCenter Cluster
        Write-Host -ForegroundColor Blue "Adding $newcluster to vCenter"

        #matching NetApp HCI defaults:
        #  HAEnabled, AddmissionControlEnabled, HAfailoverlevel2,
        #  swap withVM, DRS fullyautomated, Default VM restart Medium,, isolation disabled

        New-Cluster -Name $newcluster -Location $location -HAEnabled -HAAdmissionControlEnabled -HAFailoverLevel 2 -VMSwapfilepolicy "withVM" -HARestartPriority "Medium" -HAIsolationResponse "DoNothing" -DRSEnabled -DRSAutomationLevel "FullyAutomated"

      }

      $check = Read-Host "Would you like to create a new VDS Distributed Switch to add to $location? y/n [n]"
      if ($check -eq "y")
      {
        Write-Host -ForegroundColor Blue "Current variables for this section include"
        Write-Host -ForegroundColor Blue "  New VDS switch: [$newvds]"
        Write-Host -ForegroundColor Blue "  Number of uplinks: [$numuplinks]"
        Write-Host -ForegroundColor Blue "  Management Port Group: [$managementPG] on VLAN [$mgmtVLAN]"
        Write-Host -ForegroundColor Blue "  iSCSI-A Port Group: [$iscsiaPG] on VLAN [$iscsiVLAN]"
        Write-Host -ForegroundColor Blue "  iSCSI-B Port Group: [$iscsibPG] on VLAN [$iscsiVLAN]"
        Write-Host -ForegroundColor Blue "  VM_Network Port Group: [$vmPG] on VLAN [$vmnetworkVLAN]"
        Write-Host -ForegroundColor Blue "  vMotion Port Group: [$vmotionPG] on VLAN [$vmotionVLAN]"
        $check = Read-Host "Do you need to quit to change values in scale-vars.ps1? y/n [n]"
        if ($check -eq "y")
        {
          break;
        }

       Write-Host -ForegroundColor Blue "Adding $newvds to vCenter"
        New-VDSwitch -Location $location -Name $newvds -NumUplinkPorts $numuplinks -Mtu 9000 -LinkDiscoveryProtocol "LLDP" -LinkDiscoveryProtocolOperation "Both"
        (Get-VDSwitch $newvds | get-view).EnableNetworkResourceManagement($true)

        $dvsLink = @{

            'dvUplink1' = $dvuplink1
            'dvUplink2' = $dvuplink2
            'dvUplink3' = $dvuplink3
            'dvUplink4' = $dvuplink4
            'dvUplink5' = $dvuplink5
            'dvUplink6' = $dvuplink6

        }

        $vds = Get-VDSwitch -Name $newvds
        $spec = New-Object VMware.Vim.DVSConfigSpec
        $spec.ConfigVersion = $vds.ExtensionData.Config.ConfigVersion
        $spec.UplinkPortPolicy = New-Object VMware.Vim.DVSNameArrayUplinkPortPolicy
        $vds.ExtensionData.Config.UplinkPortPolicy.UplinkPortName | %{
            $spec.UplinkPortPolicy.UplinkPortName += $dvsLink[$_]
        }
        $vds.ExtensionData.ReconfigureDvs($spec)


        New-VDPortGroup -VDSwitch $newvds -Name "$managementPG" -NumPorts 8 -VlanID $mgmtVLAN
        Get-VDportgroup "$managementPG" -VDswitch "$newvds" | Get-VDPortgroupOverridePolicy | Set-VDPortGroupOverridePolicy -TrafficShapingOverrideAllowed $false -VlanOverrideAllowed $true -SecurityOverrideAllowed $true
        Get-VDportgroup "$managementPG" -VDswitch "$newvds" | Get-VDTrafficShapingPolicy -Direction In | Set-VDTrafficShapingPolicy -Enabled $true -AverageBandwidth 1000000000 -BurstSize 65536000 -PeakBandwidth 1200000000
        Get-VDportgroup "$managementPG" -VDswitch "$newvds" | Get-VDTrafficShapingPolicy -Direction Out | Set-VDTrafficShapingPolicy -Enabled $true -AverageBandwidth 1000000000 -BurstSize 65536000 -PeakBandwidth 1200000000


        New-VDPortGroup -VDSwitch $newvds -Name "$iscsiaPG" -NumPorts 8 -VlanID $iscsiVLAN
        Get-VDportgroup "$iscsiaPG" -VDswitch "$newvds" | Get-VDPortgroupOverridePolicy | Set-VDPortGroupOverridePolicy -TrafficShapingOverrideAllowed $false -VlanOverrideAllowed $true -SecurityOverrideAllowed $true
        Get-VDportgroup "$iscsiaPG" -VDswitch "$newvds" | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort $uplink2 -UnusedUplinkPort $uplink1

        New-VDPortGroup -VDSwitch $newvds -Name "$iscsibPG" -NumPorts 8 -VlanID $iscsiVLAN
        Get-VDportgroup "$iscsibPG" -VDswitch "$newvds" | Get-VDPortgroupOverridePolicy | Set-VDPortGroupOverridePolicy -TrafficShapingOverrideAllowed $false -VlanOverrideAllowed $true -SecurityOverrideAllowed $true
        Get-VDportgroup "$iscsibPG" -VDswitch "$newvds" | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort $uplink1 -UnusedUplinkPort $uplink2

        New-VDPortGroup -VDSwitch $newvds -Name "$vmPG" -NumPorts 41 -VlanID $vmnetworkVLAN
        Get-VDportgroup "$vmPG" -VDswitch "$newvds" | Get-VDPortgroupOverridePolicy | Set-VDPortGroupOverridePolicy -TrafficShapingOverrideAllowed $false -VlanOverrideAllowed $true -SecurityOverrideAllowed $true
        Get-VDportgroup "$vmPG" -VDswitch "$newvds" | Get-VDTrafficShapingPolicy -Direction In | Set-VDTrafficShapingPolicy -Enabled $true -AverageBandwidth 1000000000 -BurstSize 65536000 -PeakBandwidth 1200000000
        Get-VDportgroup "$vmPG" -VDswitch "$newvds" | Get-VDTrafficShapingPolicy -Direction Out | Set-VDTrafficShapingPolicy -Enabled $true -AverageBandwidth 1000000000 -BurstSize 65536000 -PeakBandwidth 1200000000


        New-VDPortGroup -VDSwitch $newvds -Name "$vmotionPG" -NumPorts 8 -VlanID $vmotionVLAN
        Get-VDportgroup "$vmotionPG" -VDswitch "$newvds" | Get-VDPortgroupOverridePolicy | Set-VDPortGroupOverridePolicy -TrafficShapingOverrideAllowed $false -VlanOverrideAllowed $true -SecurityOverrideAllowed $true
        Get-VDportgroup "$vmotionPG" -VDswitch "$newvds" | Get-VDTrafficShapingPolicy -Direction In | Set-VDTrafficShapingPolicy -Enabled $true -AverageBandwidth 1000000000 -BurstSize 65536000 -PeakBandwidth 1200000000
        Get-VDportgroup "$vmotionPG" -VDswitch "$newvds" | Get-VDTrafficShapingPolicy -Direction Out | Set-VDTrafficShapingPolicy -Enabled $true -AverageBandwidth 1000000000 -BurstSize 65536000 -PeakBandwidth 1200000000

        Write-Host -ForegroundColor Blue "VDS Switch $newvds has been added to $newcluster"

      }



     }

  3 {
      ###################################################################################################
      ##### Add ESXi host to $newcluster and configure host networking to integrate into [$hcivds]
      ###################################################################################################
      $ask = Read-Host "Are you adding ESXi host to a new VDS [$newvds] created in step 2 [y/n]"
      if ($ask -eq "y")
      {
        $hcivds = $newvds
        $iscsiA = $iscsiaPG
        $iscsiB = $iscsibPG
        $vmotion = $vmotionPG
        $mgmt_portgroup_var = $managementPG

      }
       # grab VDS info
      $vds = Get-VDSwitch -Name $hcivds

      #### Start of adding host section ####
      $vmhost = Read-Host "Enter FQDN or IP of ESXi host to add to $newcluster if different from [$s_vmhost]"
         if([string]::IsNullOrWhiteSpace($vmhost))
          {
            $vmhost=$s_vmhost
          }

      #Write-Host "VM host: $vmhost and location is $newcluster"
      #break;
      # Add Host to vCenter Cluster defined above
      Write-Host -ForegroundColor Blue "Adding $vmhost to $newcluster"
      $rcred = Get-Credential -Message "Enter credentials using user [root] and its password"
      Add-VMhost $vmhost -Location $newcluster -Credential $rcred -Force

      #verify that the host has been added to $newcluster
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

      Write-Host -ForegroundColor Blue "[$vmhost] has been added to [$newcluster]. Starting network configuration and migration from VSS to VDS"

      #verifying physical nics are the correct vmnic numbers
      $nic1 = Read-Host "If this is the correct 1st 10/25G connected physical nic for the new ESXi host, continue, otherwise enter value [$nic1var]"
        if([string]::IsNullOrWhiteSpace($nic1))
          {
            $nic1=$nic1var
          }
      $nic2 = Read-Host "If this is the correct 2nd 10/25G connected physical nic for the new ESXi host, continue, otherwise enter value [$nic2var]"
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
          Start-Sleep -s 3


          Remove-VirtualSwitch -VirtualSwitch "vSwitch0" -Confirm:$false

          Write-Host -ForegroundColor Blue "Removed vSwitch0 from [$vmhost]"


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
  4 {
      ###################################################################################################
      ##### Setup SolidFire connections to [$newcluster] and add additional datastores on SolidFire [$sf]
      ###################################################################################################

      # SolidFire connection to add ESXi host(s) into:
      $sf = Get-SFClusterInfo | select Name -ExpandProperty Name

      #Setup connections for the new host to NetApp SolidFire [$sf]"
      Write-Host -ForegroundColor Blue "Items included in this section includes:"
      Write-Host -ForegroundColor Blue "  Creating new account called [$newcluster]"
      Write-Host -ForegroundColor Blue "  Creating # of volumes of X size and specified QoS settings on SolidFire"
      Write-Host -ForegroundColor Blue "  Adding these volumes to $accessgroup access group"
      Write-Host -ForegroundColor Blue "  Adding SolidFire SVIP to ESXi host(s) that reside within $newcluster"
      Write-Host -ForegroundColor Blue "  Creating VMware datastores on ESXi hosts based on the volumes created"
      Write-Host -ForegroundColor Blue "  Rescanning adapters to complete the setup"
      $continue = Read-Host "Do you want to continue with integrating these ESXi hosts with SolidFire?[y/n]"
      If ($continue -eq "y"){
        #This assumes that New-TenantOrCluster-NetAppHCI.ps1 resides in the same directory as this script
        #This script also assumes an active session to both vCenter and SolidFire
        Write-Host -ForegroundColor Blue "Datastores to add: [$qtyvol] of size [$sizeGB GB] using QoS Min [$min], Max [$max] and Burst [$burst] IOPs"
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

  5 {
       ###################################################################################################
       ##### Disconnect from vCenter and SolidFire
       ###################################################################################################

       disconnect-viserver -server $viserver
       disconnect-sfcluster -target $sfconnect

    }

  6 {
      ###################################################################################################
      ##### Custom Section if needed to start/stop at a specific spot
      ###################################################################################################


    }


  7 {
     ###################################################################################################
     ##### Custom Section if needed to start/stop at a specific spot
     ###################################################################################################

    }
  default
    {
      $Choice=0
    }
}
}
