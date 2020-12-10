Write-Host
Write-Host "Deleting Volumes"
$account_name = "PS-Demo"
#$account_name = Read-Host "Account Name"
$name = Read-Host "Volume Name prefix to delete"
[uint16]$number = Read-Host "Number of Volumes to delete"
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
{
  $del = Get-SFVolume -Name $name-$i | select Name
  if ($del.name -eq "$name-$i")
    {
       Get-SFVolume -Name $name-$i | Remove-SFVolume
       echo "removed volume $name-$i"
    }
}

# End of Delete Volumes
