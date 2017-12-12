#script to change Storage QoS settings after inputting the volume name and new QoS settings
Write-Host
$name = Read-Host "Volume Name"

#CHECK THAT VOLUME EXISTS#
[single]$check = Get-SFVolume -Name $name | select VolumeID -ExpandProperty VolumeID
if ($check -lt 1){
 Write-Host "Volume does not exist"
 break
}

#Show Current QoS
$name2 = get-sfvolume -Name $name | select Qos
echo "Current QoS Setting $name2"

#INPUT QOS#
[single]$min = Read-Host "Min IOPS"
[single]$max = Read-Host "Max IOPS"
[single]$burst = Read-Host "Burst IOPS"

#VERIFY QoS REQUIREMENTS#
if ($max -lt $min){
 Write-Host "Max is less than Min, must be equal or greater"
 break
 }
if ($burst -lt $max){
 Write-Host "Burst is less than Max, must be equal or greater"
 break
 }

Get-SFVolume -Name $name | Set-SFVolume -MinIOPS $min -MaxIOPS $max -BurstIOPS $burst -Confirm:$false
#echo "New QoS Setting: get-sfvolume -Name $name | select Name, Qos, VolumeID"

