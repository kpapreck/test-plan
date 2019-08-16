Write-Host
Write-Host "Creating Volumes"
$source_cluster = "10.26.69.178"
$target_cluster = ""
$account_name = "PS-Demo"
#$account_name = Read-Host "Account Name"
$name = Read-Host "Source Volume Name"
$name_target = Read-Host "Target Volume Name"
[uint16]$size = Read-Host "Size in GB"
[uint16]$min = Read-Host "Min IOPS"
[uint16]$max = Read-Host "Max IOPS"
[uint16]$burst = Read-Host "Burst IOPS"
[uint16]$number = Read-Host "Number of Volumes"
echo $min $max $burst
if ($max -lt $min){
 Write-Host "Max is less than Min, must be equal or greater"
 break
 }
if ($burst -lt $max){
 Write-Host "Burst is less than Max, must be equal or greater"
 break
 }
$existing_accounts = Get-SFAccount
$test = $false
foreach ($obj in $existing_accounts){ 
 if ($obj.UserName -eq $account_name) {
  $test = $true
  break
 }
}
if ($test -eq $false){
 Write-Host "Creating new account: "$account_name
 New-SFAccount -UserName $account_name
 }
$account = Get-SFAccount $account_name

for ($i=0; $i -le ($number-1); $i++)
{New-SFVolume -Name $name-$i -AccountID $account.AccountID -Enable512e:$false -TotalSize $size -GB -MinIOPS $min -MaxIOPS $max -BurstIOPS $burst -target $source_cluster
$source_id = get-sfvolume $name-$i | select VolumeID -ExpandProperty VolumeID
$source_vol = Start-SFVolumePairing -VolumeID $source_id -mode Async 
New-SFVolume -Name $name_target-$i -AccountID $account.AccountID -Enable512e:$false -TotalSize $size -GB -MinIOPS $min -MaxIOPS $max -BurstIOPS $burst -target $target_cluster
$target_id = get-sfvolume $name_target-$i | select VolumeID -ExpandProperty VolumeID
Set-SFVolume -VolumeID $target_id -Access replicationTarget
Complete-SFVolumePairing -VolumeID $target_id -VolumePairingKey $source_vol.VolumePairingKey
}
# End of Create Volumes
echo "Show Volumes that include name from above: get-sfaccount -username PS-Demo | get-sfvolume | select Name, Qos, VolumeID"
get-sfaccount -username PS-Demo | get-sfvolume | select Name, Qos, VolumeID 
#get-sfvolume *$name* | select Name, Qos
