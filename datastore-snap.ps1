#Script to create snapshot on any volumes starting with HCI-Auto-
Write-Host
$name = Read-Host "Volume Name"

#CHECK THAT VOLUME EXISTS#
[uint16]$check = Get-SFVolume -Name $name | select VolumeID -ExpandProperty VolumeID
if ($check -lt 1){
 Write-Host "Volume does not exist"
 break
}

#create a snapshot without specifying a name
#Get-SFVolume -Name $name | New-SFSnapshot

#create a snapshot with a name
$snap = Read-Host "Snapshot Name"
Get-SFVolume -Name $name | New-SFSnapshot -Name $snap
