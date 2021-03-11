. ./scale-vars.ps1
Get-VDSwitch -Name "NetApp HCI VDS 01" | New-VDSwitch -Name "MyVDSwitch" -Location $location -WithoutPortGroups
