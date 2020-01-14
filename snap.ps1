$dsname = "NetApp-HCI-Datastore-01"
$ds = Get-Datastore $dsname | Get-VM
foreach($d in $ds)
{
	write-host $d.Name
        new-snapshot -VM $d -Name $d -Quiesce
}
write-host "consistent snapshots are complete, now creating element snapshot"
#snapshot the Element volume with the same name as the datastore name
Get-SFVolume -Name $dsname | New-SfSnapshot -Name $consistent-snap
foreach($d in $ds)
{
        write-host $d.Name
        get-vm $d.Name | get-snapshot | remove-snapshot -confirm:$false
}
write-host "clean up complete"
