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

#solidfire MVIP
$sfconnect = "10.45.85.191"

#vCenter IP/FQDN
$viserver = "10.45.85.185"


#Compute cluster name to add to datacenter
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


##### variables that I added that are different from typical setup #####
$mgmt_portgroup_var = "Management Network 89"



##### ESXi Host Information #####
#ESXi physical 10/25G nics to add into VDS
$nic1var = "vmnic0"
$nic2var = "vmnic1"


#ESXi host ip information for scaling compute
# VM host properties
$s_vmhost = "winf-evo3-blade4.ntaplab.com"

#iscsiA IP
$s_ip1 = "10.45.91.217"

#iscsiB IP
$s_ip2 = "10.45.91.218"

#iscsi subnet
$iscsiSubnet_var = "255.255.255.0"

#vmotion ip for ESXi host
$s_ip3 = "10.45.89.191"

#vmotion subnet
$vmotionSubnet_var = "255.255.255.0"

###################################################################################################
##### Optional Section Depending on Options
###################################################################################################
##### SolidFire Information #####
#number of datastores to create
$qtyvol = "1"

#size of datastore(s) to create
$sizeGB = "1024"

#Qos settings
$min = "1000"
$max = "10000"
$burst = "50000"


##### Variables for creating new environment for 3rd party #####
#new datacenter and cluster to add to vCenter
$location2 = "NetApp-Datacenter-02"
$newcluster2 = "NetApp-Cluster-02"

$newvds = "NetApp HCI VDS 02"
$numuplinks = 2
$mgmtVLAN = 89
$iscsiVLAN = 91
$vmnetworkVLAN = 89
$vmotionVLAN = 89

$managementPG = "$newvds-Management"
$iscsiaPG = "$newvds-iSCSI-A"
$iscsibPG = "$newvds-iSCSI-B"
$vmPG = "$newvds-VM_Network"
$vmotionPG = "$newvds-vMotion"
