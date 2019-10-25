<##############################################################################
Script to clone a datastore and present it back to vmware
1. Initiates connections to element and vmware
2. Asks user for the volume name of the datastore it will clone
3. Lists snapshots associated to the volume
4. Asks for user input of the snapshot to use for the clone
5. Creates clone of the snapshot
6. presents clone to vmware and resignatures it as a datastore to recover vms
################################################################################>

##################
#setup connections
##################
Connect-SFCluster -Target $hci -UserName $hciuser -Password $cred
Connect-VIServer -Server $vcenterip -User $vuser -Password $cred

#######################################
#grab datastore volume and snapshotinfo
#######################################

#grab the volume name
$name = Read-Host "Volume name of datastore you are restoring"

If(!(Get-SFVolume $name) -notcontains ""){
Write-Host "There are no volumes with this name"
Write-Host "quitting script"
break;
}

#grab the volumeid from the volume you entered above
$vname = get-sfvolume -name $name
$volid = $vname.VolumeID
$volaccessgroups = $vname.VolumeAccessGroups

#list all snapshots associated with the volume

$snaplist = Get-SFVolume -Name $name | get-sfsnapshot
If(!($snaplist) -notcontains ""){
Write-Host "There are no snapshots associated with volume $name"
Write-Host "quitting script"
break;
}
Get-SFVolume -Name $name  | get-sfsnapshot

$snapid = Read-Host "What SnapshotID would you like to clone"


###########################################################
#create a clone from the original volume id and snapshot id
###########################################################

$ms = (get-date).millisecond
$clonename = $name + $ms
$newclone = New-SFClone -VolumeID $volid -SnapshotID $snapid -Name $clonename
Write-Host "waiting for clone to complete"

#loop process until the clone has completed

while($running -eq $null){
 if($CheckUser -le '100'){
  $CheckUser++
  start-sleep -s 10
  $running = Get-sfvolume -volumeid $newclone.VolumeID
  write-host "waiting for clone to repeat. will try again in 10 seconds"
}else{
write-host "not working"
}
}
write-host "clone creation has completed. continuing"


#add volume to SF AccessGroup and account

$clonevol = Get-SFVolume $clonename

foreach ($number in $volaccessgroups){Add-SFVolumeToVolumeAccessGroup -VolumeID $clonevol.VolumeID -VolumeAccessGroupID $number} 

###################################################
#take clone, create datastore, and map it to vmware
###################################################

#rescan VMware
Get-VMhost | Get-VMhostStorage -RescanAllHba -RescanVMFs 

#setup esxlci
$vmhost = Get-VMhost | Select -First 1
$esxcli = Get-EsxCLi -VMhost $vmhost

#list snapshots to find the cloned volume
$snaplist = $esxcli.storage.vmfs.snapshot.list()
$esxcli.storage.vmfs.snapshot.resignature($name)


