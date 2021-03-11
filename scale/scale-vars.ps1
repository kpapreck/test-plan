#       ======================================================================
#       Disclaimer: This script is written as best effort and provides no
#       warranty expressed or implied. Please contact the author(s) if you
#       have questions about this script before running or modifying
#
#       Do not run this code in a production environment without first testing
#       ======================================================================

#       This code will is used to gather information for scaling NetApp HCI
#	To run: . ./scale-vars.ps1


###################################################################################################
##### Connection variables used
###################################################################################################
#solidfire MVIP
$sfconnect = "10.45.85.191"

#vCenter IP/FQDN
$viserver = "10.45.85.185"


###################################################################################################
##### Required variables for vCenter cluster/datacenter
###################################################################################################

#Compute cluster name to add to datacenter
$newcluster = "NetApp-Cluster-02"

#vCenter Datacenter to Add Host/Cluster to [Default NetApp HCI: "NetApp-HCI-Datacenter-01"]
$location = "NetApp-Datacenter-02"


###################################################################################################
##### Required variables for adding ESXi host to existing VDS switch with 2 uplink
###################################################################################################

#VDS to add cluster into [Default NetApp HCI: "NetApp HCI VDS 01"]
$hcivds = "NetApp HCI VDS 01"

#ESXi standard switch to migrate to VDS after adding to the cluster
$switch = "vSwitch0"

#ESXi Uplinks [Default NetApp HCI: "Uplink 1" and "Uplink 2"]
$uplink1 = "Uplink 1"
$uplink2 = "Uplink 2"

#NetApp HCI VDS Port Group Names for migration
#Default iSCSI for NetApp HCI are: []"NetApp HCI VDS 01-iSCSI-A"] ["NetApp HCI VDS 01-iSCSI-B]
#Default vMotion for NetApp HCI is: []"NetApp HCI VDS 01-vMotion"]
#Default Management for NetApp HCI is: ["NetApp HCI VDS 01-Management_Network"]
$iscsiA = "NetApp HCI VDS 01-iSCSI-A"
$iscsiB = "NetApp HCI VDS 01-iSCSI-B"
$vmotion = "NetApp HCI VDS 01-vMotion"
$mgmt_portgroup_var = "NetApp HCI VDS 01-Management_Network"


##### variables that I added that are different from typical setup #####
$mgmt_portgroup_var = "Management Network 89"




###################################################################################################
##### Required variables for adding new VDS
###################################################################################################
#new datacenter and cluster to add to vCenter
#$location2 = "NetApp-Datacenter-02"
#$newcluster2 = "NetApp-Cluster-02"

$newvds = "NetApp VDS 02"
$numuplinks = 2
$mgmtVLAN = 89
$iscsiVLAN = 91
$vmnetworkVLAN = 89
$vmotionVLAN = 89

#VDS uplink names
$dvuplink1 = "Uplink 1"
$dvuplink2 = "Uplink 2"
$dvuplink3 = "Uplink 3"
$dvuplink4 = "Uplink 4"
$dvuplink5 = "Uplink 5"
$dvuplink6 = "Uplink 6"

#Port group names for new VDS switch
$managementPG = "$newvds-Management"
$iscsiaPG = "$newvds-iSCSI-A"
$iscsibPG = "$newvds-iSCSI-B"
$vmPG = "$newvds-VM_Network"
$vmotionPG = "$newvds-vMotion"

###################################################################################################
##### Required variables for compute node into vCenter
###################################################################################################
##### ESXi Host Information #####
#ESXi physical 10/25G nics to add into VDS
$nic1var = "vmnic0"
$nic2var = "vmnic1"


#ESXi host ip information for scaling compute
#VM host IP or FQDN to add to environment
$s_vmhost = "winf-evo3-blade4.ntaplab.com"

#iscsiA IP for host you are adding
$s_ip1 = "10.45.91.217"

#iscsiB IP for host you are adding
$s_ip2 = "10.45.91.218"

#iscsi subnet for host you are adding
$iscsiSubnet_var = "255.255.255.0"

#vmotion ip for ESXi host you are adding
$s_ip3 = "10.45.89.191"

#vmotion subnet for host you are adding
$vmotionSubnet_var = "255.255.255.0"

###################################################################################################
##### Optional Section Depending on Options
###################################################################################################
##### SolidFire Information #####

#access group to use [Default NetApp HCI: "NetApp-HCI"]
$accessgroup="$newcluster"

#number of datastores to create
$qtyvol = "1"

#size of datastore(s) to create
$sizeGB = "1024"

#Qos settings
$min = "1000"
$max = "10000"
$burst = "50000"
