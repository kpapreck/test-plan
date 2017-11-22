#Script to create snapshot on any volumes starting with HCI-Auto-
Get-SFVolume -Name "HCI-Auto-*" | New-SFSnapshot -Name HCI-Auto-Snapshot
