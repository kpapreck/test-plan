#script to enter volume name and get the efficiency of that individual volume

Write-Host
$name = Read-Host "Volume Name"

#CHECK THAT VOLUME EXISTS#
[uint16]$check = Get-SFVolume -Name $name | select VolumeID -ExpandProperty VolumeID
if ($check -lt 1){
 Write-Host "Volume does not exist"
 break
}


Get-SFVolume -Name $name | get-sfvolumeefficiency  
