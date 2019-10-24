Connect-SFCluster -Target $hci -UserName $hciuser -Password $cred
Connect-VIServer -Server $vcenterip -User $vuser -Password $cred

$name = Read-Host "Volume name of datastore you are restoring"

#list all snapshots associated to the volume name
Get-SFVolume -Name $name  | get-sfsnapshot

#grab the volumeid from the volume you entered above
$volid = get-sfvolume -name $name | select VolumeID -ExpandProperty VolumeID

#list all snapshots


#list snapshots associated to this volume in order followed by their create time and select that SnapshotID 
Get-SFVolume -Name $name | Get-SFSnapshot
#$associatedsnap = Get-SFVolume -Name $name | Get-SFSnapshot
#$associatedsnap = $associatedsnap.SnapshotID, $associatedsnap.CreateTime 

$snapid = Read-Host "What SnapshotID would you like to clone"

#create a clone from the original volume id and snapshot id
$ms = (get-date).millisecond
$clonename = $name + $ms
$newclone = New-SFClone -VolumeID $volid -SnapshotID $snapid -Name $clonename
$newcloneasync = $newclone.asyncHandle
Write-Host "waiting for clone to complete"


#NEED TO CREATE LOOP TO CHECK FOR CLONE TO COMPLETE UNTIL KEYPRESS
<#
DO
{
 $clonestatus = get-sfasyncresult $newcloneasync
 #Write-Host $clonestatus
}
until ("if ([console]::KeyAvailable)
Write-Host "Clone Status" $clonestatus
#>




Read-Host "wait for clone to complete - once complete hit enter"

#Add the newly created clone to the NetApp-HCI AccessGroup
#add volume to SF AccessGroup and account NetApp-HCI
$account = Get-SFAccount NetApp-HCI
$volumes = Get-SFVolume $clonename
$vag = Get-SFVolumeAccessGroup -Name NetApp-HCI
$volumes | Add-SFVolumeToVolumeAccessGroup -VolumeAccessGroupID $vag.VolumeAccessGroupID

#rescan VMware
Get-VMhost | Get-VMhostStorage -RescanAllHba -RescanVMFs 

#setup esxlci
$vmhost = Get-VMhost | Select -First 1
$esxcli = Get-EsxCLi -VMhost $vmhost

#list snapshots to find the cloned volume
$snaplist = $esxcli.storage.vmfs.snapshot.list()
#$vmfsname = $snaplist.VolumeName
$esxcli.storage.vmfs.snapshot.resignature($name)


