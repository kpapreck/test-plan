while($running -eq $null){
 if($CheckUser -le '100'){
  $CheckUser++
  start-sleep -s 10
  $running = Get-sfvolume -volumeid 104
  write-host "waiting for clone to repeat. will try again in 10 seconds"
}else{
write-host "not working"
}
}
write-host "clone creation has completed. continuing"











#If(!(Get-SFVolume $name) -notcontains ""){
#Write-Host "There are no volumes with this name"
#Write-Host "quitting script"
#break;
#}
#$snaplist = Get-SFVolume -Name $name | get-sfsnapshot
#If(!($snaplist) -notcontains ""){
#Write-Host "There are no snapshots associated with volume $name"
#Write-Host "quitting script"
#break;
#}
#Get-SFVolume -Name $name  | get-sfsnapshot


#If(!(Get-SFAsyncResult $23) -notcontains ""){ Write-Host "waiting"}

