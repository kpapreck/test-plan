#       ======================================================================
#       Disclaimer: This script is written as best effort and provides no
#       warranty expressed or implied. Please contact the author(s) if you
#       have questions about this script before running or modifying
#       
#       Do not run this code in a production environment without first testing
#       ======================================================================

#       This code will is used to gather information for scaling NetApp HCI
#	To run: . ./scale-vars.ps1

###Description of Variables###
# newcluster = name of the new cluster being created
# location = the datacenter within NetApp HCI to add the cluster
# hcivds = the existing VDS switch that you are looking to add the new hosts into
# nic1 and nic2 are the vmnics of the new host adding to the cluster
# Uplinks are the uplinks to add to for a 2-cable setup
# switch = VSS switch created by default before adding 
# iscsiA/iscsiB/vmotion = vmk port group names from existing VDS to integrate into the new host
# iscsiSubnet = subnet used for iscsiA/iscsiB
# vmotionSubnet = subnet used for vmotion


#vCenter IP/FQDN
$viserver = "10.10.10.10"

#solidfire MVIP
$sfconnect = "10.10.10.11"

#Compute cluster name to add to NetApp HCI Datacenter
$newcluster = "mycluster"


##### Variables using Default NetApp HCI Setup #####
#vCenter Datacenter to Add Host/Cluster to [Default: "NetApp-HCI-Datacenter-01"]
$location = "NetApp-HCI-Datacenter-01"

#NetApp HCI VDS to add cluster into [Default: "NetApp HCI VDS 01"]
$hcivds = "NetApp HCI VDS 01"

#ESXi standard switch to migrate to VDS after adding to the cluster
$switch = "vSwitch0"

#ESXi Uplinks
$uplink1 = "Uplink 1"
$uplink2 = "Uplink 2"

#NetApp HCI VDS Port Group Names for migration
$iscsiA = "NetApp HCI VDS 01-iSCSI-A"
$iscsiB = "NetApp HCI VDS 01-iSCSI-B"
$vmotion = "NetApp HCI VDS 01-vMotion"
$mgmt_portgroup_var = "NetApp HCI VDS 01-Management_Network"



##### ESXi Host Information #####
#ESXi physical 10/25G nics to add into VDS
$nic1var = "vmnic0"
$nic2var = "vmnic1"


#ESXi host ip information for scaling compute
# VM host properties
$s_vmhost = "newhost.netapp.com"

#iscsiA IP
$s_ip1 = "10.12.10.100"

#iscsiB IP
$s_ip2 = "10.12.10.101"

#iscsi subnet
$iscsiSubnet_var = "255.255.255.0"

#vmotion ip for ESXi host
$s_ip3 = "10.11.10.100"

#vmotion subnet
$vmotionSubnet_var = "255.255.255.0"


##### SolidFire Information #####
#number of datastores to create
$qtyvol = "1"

#size of datastore(s) to create
$sizeGB = "1024"

#Qos settings
$min = "1000"
$max = "10000"
$burst = "50000"


