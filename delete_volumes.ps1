Write-Host
Write-Host "Deleting Volumes"
$name = Read-Host "Volume Name prefix to delete"
[uint16]$number = Read-Host "Number of Volumes to delete"

for ($i=0; $i -le ($number-1); $i++)
{
  $del = Get-SFVolume -Name $name-$i | select Name
  if ($del.name -eq "$name-$i")
    {
       Get-SFVolume -Name $name-$i | Remove-SFVolume
       echo "removed volume $name-$i"
    }
}

# End of Delete Volumes
