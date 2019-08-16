#script to enter volume name and get the efficiency of that individual volume

Write-Host
$name = Read-Host "Volume Name"

#CHECK THAT VOLUME EXISTS#
[uint16]$check = Get-SFVolume -Name $name | select VolumeID -ExpandProperty VolumeID
if ($check -lt 1){
 Write-Host "Volume does not exist"
 break
}

$nonZero = Get-SFVolumestats -volumeid $check | select NonZeroBlocks -ExpandProperty NonZeroBlocks 
$zero = Get-SFVolumestats -volumeid $check | select ZeroBlocks -ExpandProperty ZeroBlocks
$percentFull = ($nonZero/($nonZero+$Zero))*100

$nonZero = ($nonZero*4/1000/1000)

$nonZero = "{0:N2}" -f $nonZero
$percentFull = "{0:N2}" -f $percentFull
Write-Host "Volume $name is currently using $nonZero GB and is $percentFull % Full"
#Get-SFVolume -Name $name | get-sfvolumeefficiency  
