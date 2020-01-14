##
##  This script will reset the QOS policy values for each CPOC created policy.
##  It will set them to the values defined in the HCI-variables file


$ScriptRoot = Split-Path $MyInvocation.MyCommand.Path
. "$ScriptRoot\HCI-variables.ps1"

###  Connect to SolidFire Cluster
write-host "Connecting to SolidFire cluster...."
Connect-sfcluster -target $mvip -username $SFadmin -password $SFpassword | out-null

Write-host " "
foreach ($vmName in $vmNameList) {

  $vmNameStr = $vmName[0]
  write-host "Setting QOS Policy for....:  $vmNameStr"
  Get-SFQosPolicy -name $vmNamestr | set-SFQosPolicy -MinIOPS $infraMinIOPS -MaxIOPS $infraMaxIOPS -BurstIOPS $infraBurstIOPS | out-null

}


