###
###
#  This file contains the variables necessary to run the HCI Setup Scripts
#
#
###



# SolidFire Cluster
$mvip = "10.254.1.104"
$svip = "10.254.2.105"
$SFadmin = "admin"
$SFaccount = "CPOCtester"
$SFvag = "NetApp-HCI"

$SFpassword = "netappHCI123!"

# vCenter
$vCenter="10.254.1.100"
$vCenterUser="admin@vsphere.local"
$vCenterUserPassword=$SFpassword

#ESX host for cloning
$esxhost ="10.254.1.103"

# Name of template to be used as source for cloning
$VMclone = "CPOC_Kit"
$VMcloneSrc = "CPOC_SRC"

#ESX Host Password
$HCpassword = ConvertTo-SecureString -AsPlainText -Force $SFpassword

#Guest VM Password - Template
$GCpassword = ConvertTo-SecureString -AsPlainText -Force "Netapp123"

# Create Credentials
$hc = New-Object System.Management.Automation.PSCredential -ArgumentList "root", $HCpassword
$gc = New-Object System.Management.Automation.PSCredential -ArgumentList "root", $GCpassword


# Infrastructure datastore
$infraDS = "HCI-infra"
$infraVolSize = "1536"
$infraMinIOPS = 1000
$infraMaxIOPS = 100000
$infraBurstIOPS = 100000


#QOS Demo VM Attributes
$vmNameList = @()
#
# This creates an array with vmname and then the last octet for the vm IP address
# It also is used for the volume names that get created
#
# This will create 4 VMs of each name and they will be numbered 1-4
# They will have 5 volumes of 100g each
#
#
$vmNameList = @(("sql", "40"), ("mongo", "50"),("devops", "60"),("bullys", "70"))
#$vmNameList = @(("sql", "40"), ("mongo", "50"))
$vmStart = 1
$vmCount = 4
$volSize = 100
$numVols = 5

##  New datastore cluster vars
$dsCount = 20
$dsSize = 1024
$vDataCenter = "NetApp-HCI-Datacenter"



# Bokeh Server
# this is the vm that runs the graphing program
$bokehIP = "10.254.1.71"
$bokeh = "CPOCbokeh"

# IP Information
$ipBase = "10.254.1."
$ipGateway = "10.254.1.251"
$ipDNS = "10.254.1.251"

