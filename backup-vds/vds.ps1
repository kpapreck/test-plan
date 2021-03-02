Start-Transcript -Append -Path "$env:USERPROFILE\Documents\DVScopy.log"
$vCenterIP = "10.45.85.185"
$myDatacenter = "NetApp-HCI-Datacenter-01"
$Cluster = "mycluster"
$NewDVS = "NetApp HCI VDS 01"

#$vCenterIP = Read-Host "Enter vCenter IP or Name where the operation needs to be executed"
#$myDatacenter = Read-Host "Enter Datacenter Name where the operation needs to be executed"
#$Cluster = Read-Host "Enter Cluster Name where the operation needs to be executed"
#$NewDVS = Read-Host "Enter a Name for the DVS in the New vCenter"
#Connect-VIServer $vCenterIP
[uint16]$Choice=1
While ($Choice -ne 0)
{
Write-Host -ForegroundColor Red "Step 1,2 and 3 are expected to be run sequentially. Unless you have migrated all the VM to $NewDVS and would like to execute Step 2 to move additional Nic"
Write-Host -ForegroundColor Green "What would you like to do?"
Write-Host -ForegroundColor Green "1: Add Hosts to $NewDVS"
Write-Host -ForegroundColor Green "2: Move Physical Nics to $NewDVS"
Write-Host -ForegroundColor Green "3: Move VMs to $NewDVS"
Write-Host -ForegroundColor Green "0: Exit"
[uint16]$Choice=Read-Host "Select the operation you would like to perform [0]"
$hostnames=Get-Datacenter -Name $myDatacenter | Get-Cluster -Name $Cluster | Get-VMHost
$hostnames=$hostnames.name
switch($Choice) 
{
   1 {
        Write-Host -ForegroundColor Green "You have selected to add Hosts to $NewDVS"         
        ################Adding the Host to the new DVS by reading the host list########################
        ForEach ($hostname in $hostnames)
        {
        Get-VDSwitch -Name $NewDVS|Add-VDSwitchVMHost -VMHost $hostname -Confirm:$false
        Write-Host -ForegroundColor Green "Added $hostname to $NewDVS"
        }
      } 
        
   2 {
        Write-Host -ForegroundColor Green "You have selected to Move Physical Nics to $NewDVS"      
        ################Move Physical Nics######################################
        $NicName=Read-Host "Enter a Name of the Physical Nic to move [vmnic0]"
        $UplinkName=Read-Host "Enter a Name of the DVS Uplink to use for $NicName [Uplink 1]"
        Write-Host -ForegroundColor Red "Moving Physical Nic $NicName for all Hosts in the  slected cluster to $NewDVS $UplinkName.This can lead to Network outage"
        $Execute ="no"
        While ($Execute -ne "yes")
        {
        $Execute =Read-Host "Should I proceed[yes]"
        }
        ForEach ($hostname in $hostnames)
        {
          $NicCount = (Get-VDSwitch -Name $NewDVS|Get-VMHostNetworkAdapter -Physical |  Where-Object {$_.VMHost.Name -eq $hostname}).count
          if ($NicCount -eq 0)
            {
              $EsxHost = Get-VMHost -Name $hostname
              $vds = Get-VDSwitch -Name $NewDVS -VMHost $EsxHost
              $uplinks = Get-VDPort -VDSwitch $vds -Uplink | where {$_.ProxyHost -like $hostname}
              $netSys = Get-View -Id $EsxHost.ExtensionData.ConfigManager.NetworkSystem
              $config = New-Object VMware.Vim.HostNetworkConfig
              $SwitchConfig = New-Object VMware.Vim.HostProxySwitchConfig
              $SwitchConfig.Uuid = $vds.ExtensionData.Uuid
              $SwitchConfig.ChangeOperation = [VMware.Vim.HostConfigChangeOperation]::edit
              $SwitchConfig.Spec = New-Object VMware.Vim.HostProxySwitchSpec
              $SwitchConfig.Spec.Backing = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking
              $PnicSpec = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
              $PnicSpec.PnicDevice = $NicName
              $PnicSpec.UplinkPortKey = $uplinks | where{$_.Name -eq $UplinkName} | Select -ExpandProperty Key
              $SwitchConfig.Spec.Backing.PnicSpec += $PnicSpec
              $config.ProxySwitch += $SwitchConfig
              $netSys.UpdateNetworkConfig($config,[VMware.Vim.HostConfigChangeMode]::modify)         
              Write-Host -ForegroundColor Green "Moved $NicName for $hostname to $NewDVS $UplinkName"        
            }
          else
            { 
              Write-Host -ForegroundColor red "The $hostname allready has 1 or more physical Nics on $NewDVS"
              $EsxHost = Get-VMHost -Name $hostname
              $vds = Get-VDSwitch -Name $NewDVS -VMHost $EsxHost
              $uplinks = Get-VDPort -VDSwitch $vds -Uplink | where {$_.ProxyHost -like $hostname}
              $NumUplinksUsed = ($uplinks| Where-Object {$_.ConnectedEntity.Name -like "vmnic*"}).count
              $config = New-Object VMware.Vim.HostNetworkConfig
              $config.ProxySwitch = New-Object VMware.Vim.HostProxySwitchConfig[] (1)
              $config.ProxySwitch[0] = New-Object VMware.Vim.HostProxySwitchConfig
              $config.ProxySwitch[0].Uuid = $vds.ExtensionData.Uuid
              $config.ProxySwitch[0].ChangeOperation = 'edit'
              $config.ProxySwitch[0].Spec = New-Object VMware.Vim.HostProxySwitchSpec
              $config.ProxySwitch[0].Spec.Backing = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking
              $config.ProxySwitch[0].Spec.Backing.PnicSpec = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec[] ($NumUplinksUsed+1)
              $config.ProxySwitch[0].Spec.Backing.PnicSpec[0] = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
              $config.ProxySwitch[0].Spec.Backing.PnicSpec[0].PnicDevice = $NicName
              $config.ProxySwitch[0].Spec.Backing.PnicSpec[0].UplinkPortKey = $uplinks | where{$_.Name -eq $UplinkName} | Select -ExpandProperty Key
              $PnicDevice=@()
              $UplinkPortKey=@()
              foreach ($uplink in $uplinks| Where-Object {$_.ConnectedEntity.Name -like "vmnic*"})
              {
               $PnicDevice+=$uplink.ConnectedEntity.Name
               $UplinkPortKey+=$uplink.Key                
              }
               
               $i=1
               while (($i-1) -ne $NumUplinksUsed)
               {
               $config.ProxySwitch[0].Spec.Backing.PnicSpec[$i] = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
               $config.ProxySwitch[0].Spec.Backing.PnicSpec[$i].PnicDevice = $PnicDevice[$i-1]
               $config.ProxySwitch[0].Spec.Backing.PnicSpec[$i].UplinkPortKey = $UplinkPortKey[$i-1]
               $i = $i+1 
               }
                         
              $changeMode =  [VMware.Vim.HostConfigChangeMode]::modify
              $netSys = Get-View -Id $EsxHost.ExtensionData.ConfigManager.NetworkSystem
              $netSys.UpdateNetworkConfig($config,$changeMode)
              Write-Host -ForegroundColor Green "Moved $NicName for $hostname to $NewDVS $UplinkName"
            }          
         }       
     } 
       
   3 {
        Write-Host -ForegroundColor Green "You have selected to Move VMs to $NewDVS"       
        ###################Move VMs#########################
        #Validation Prompt
        $Execute = "no"
        While ($Execute -ne "yes")
        {
        Write-Host -ForegroundColor Red "Moving VMs from one Portgroup to another will lead to a brief network outage."
        Write-Host -ForegroundColor Red "Validate and confirm the Physical Nic placement for Hosts on $NewDVS before proceding."
        $Execute=Read-Host "Would you like to proceed further with VM placement[yes]"
        }
 
        $NetMap = Import-Csv $env:USERPROFILE\Documents\Network_Map.csv
        $VMs = Get-Datacenter -Name $myDatacenter | Get-Cluster -Name $Cluster |Get-VM
         
        #Virtual Machine placement
        ForEach ($VM in $VMs)
        {
            if($VM.Name -in $NetMap.VM) 
            {
            $NetAdapters=Get-VM $VM | Get-NetworkAdapter
                ForEach ($NetAdapter in $NetAdapters)
                {
                    $NetName=$NetMap | Where-Object{($_.VM -eq $VM.Name) -and ($_.Name -eq $NetAdapter.Name)}
                    $NetName=$NetName.NetworkName
                    $error.clear()
                    try
                        {
                            Set-NetworkAdapter -NetworkAdapter $NetAdapter -Portgroup $NetName -Confirm:$false                           
                        }catch{}
                    if(!$error)
                        {
                            Write-Host -ForegroundColor Green "Moved $NetAdapter for $VM to $NewDVS PortGroup $NetName"
                        }
                    else
                        {
                            Write-Host -ForegroundColor red "Error processing $VM"
                        }
                }
             }
            else
            {
                Write-Host -ForegroundColor red "Network mapping not found for $VM"
            }
 
        }
              
     }
   default
        {
            $Choice=0
        }       
}
}
Disconnect-viserver -confirm:$false
Stop-Transcript
