###################################################################################################
##### Variables used in script
###################################################################################################
. ./scale-vars.ps1

$newvds = "NetApp HCI VDS 02"
$numuplinks = 2
$mgmtVLAN = ""
$iscsiVLAN = 91
$vmnetworkVLAN = ""
$vmotionVLAN = 89

$managementPG = "$newvds-Management"
$iscsiaPG = "$newvds-iSCSI-A"
$iscsibPG = "$newvds-iSCSI-B"
$vmPG = "$newvds-VM_Network"
$vmotionPG = "$newvds-vMotion"

New-VDSwitch -Location $location -Name $newvds -NumUplinkPorts $numuplinks -Mtu 9000 -LinkDiscoveryProtocol "LLDP" -LinkDiscoveryProtocolOperation "Both"
(Get-VDSwitch $newvds | get-view).EnableNetworkResourceManagement($true)

$dvsLink = @{

    'dvUplink1' = 'Uplink 1'
    'dvUplink2' = 'Uplink 2'
    'dvUplink3' = 'Uplink 3'
    'dvUplink4' = 'Uplink 4'
    'dvUplink5' = 'Uplink 5'
    'dvUplink6' = 'Uplink 6'

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
