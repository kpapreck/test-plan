#KEVIN PAPRECK - UNOFFICIAL SCRIPT FOR CALCULATING SOLIDFIRE EFFICIENCIES

#       ====================================================================
#       Disclaimer: This script is written as best effort and provides no
#       warranty expressed or implied. Please contact the author(s) if you
#       have questions about this script before running or modifying
#       ====================================================================

#EFFICIENCY CALCULATIONS
#thinProvisioningFactor = (nonZeroBlocks + zeroBlocks) / nonZeroBlocks
#deDuplicationFactor = (nonZeroBlocks+snapshotNonZeroBlocks) / uniqueBlocks
#compressionFactor = (uniqueBlocks * 4096) / (uniqueBlocksUsedSpace*.93)

#REQUIRED INPUTS
#$nonZeroBlocks = get-sfclustercapacity | select nonZeroBlocks -ExpandProperty nonZeroBlocks
#$zeroBlocks = get-sfclustercapacity | select zeroBlocks -ExpandProperty zeroBlocks
#$uniqueBlocks = get-sfclustercapacity | select uniqueBlocks -ExpandProperty uniqueBlocks
#$uniqueBlocksUsedSpace = get-sfclustercapacity | select uniqueBlocksUsedSpace -ExpandProperty uniqueBlocksUsedSpace
#$snapshotNonZeroBlocks = get-sfclustercapacity | select snapshotNonZeroBlocks -ExpandProperty snapshotNonZeroBlocks
#get-item $data
$data = Read-Host "Enter all text from GetClusterFullThreshold API found in activeiq.solidfire.com"
$stage4BlockThresholdBytes = $data.Split('"stage4BlockThresholdBytes":')[-1]
[single]$stage4BlockThresholdBytes=$stage4BlockThresholdBytes.split(',')[0]

#GET TOTAL CLUSTER CAPACITY
$sumUsedClusterBytes = $data.Split('"sumUsedClusterBytes":')[-1]
[single]$sumUsedClusterBytes = $sumUsedClusterBytes.split(',')[0]

$effectiveCapacity = $data.Split('"sumTotalClusterBytes":')[-1]
[single]$effectiveCapacity = $effectiveCapacity.split(',')[0]

$data2 = Read-Host "Enter all text from GetClusterCapacity API found in activeiq.solidfire.com"
$nonZeroBlocks = $data2.Split('"nonZeroBlocks":')[-1]
[single]$nonZeroBlocks = $nonZeroBlocks.split(',')[0]
$zeroBlocks =$data2.Split('"zeroBlocks":')[-1]
[single]$zeroBlocks = $zeroBlocks.split(',')[0]
$snapshotNonZeroBlocks = $data2.Split('"snapshotNonZeroBlocks":')[-1]
[single]$snapshotNonZeroBlocks = $snapshotNonZeroBlocks.split(',')[0]
$uniqueBlocks = $data2.Split('"uniqueBlocks":')[-1]
[single]$uniqueBlocks = $uniqueBlocks.split(',')[0]
$uniqueBlocksUsedSpace = $data2.Split('"uniqueBlocksUsedSpace":')[-1]
[single]$uniqueBlocksUsedSpace = $uniqueBlocksUsedSpace.split(',')[0]

#EFFICIENCY CALCULATIONS
[single]$thinProvisioningFactor = (($nonZeroBlocks+$zeroBlocks)/$nonZeroBlocks)
[single]$deDuplicationFactor = (($nonZeroBlocks+$snapshotNonZeroBlocks)/$uniqueBlocks)
[single]$compressionFactor = (($uniqueBlocks*4096)/($uniqueBlocksUsedSpace*.93))



#CALCULATE EFFICIENCY FACTOR FOR COMPRESSION + DEDUPLICATION ONLY
$efficiencyFactor = ($deDuplicationFactor*$compressionFactor)


#GET TOTAL CLUSTER CAPACITY AFTER EFFICIENCY

$effectiveCapacityRemaining =((($stage4BlockThresholdBytes - $sumUsedClusterBytes)/(1000*1000*1000*1000))*$efficiencyFactor)/2
$effectiveCapacityRemaining = "{0:N2}" -f $effectiveCapacityRemaining

#CALCULATE HOW MUCH STORAGE IS USED WITH EFFICIENCIES FACTORED IN
$effectiveUsed = ($sumUsedClusterBytes/(1000*1000*1000*1000)*$efficiencyFactor)
$effectiveUsed = "{0:N2}" -f $effectiveUsed

#CALCULATE THE EFFECTIVE CAPACITY OF THE SYSTEM UP TO 100% FULL
$effectiveCapacity = ($effectiveCapacity/(1000*1000*1000*1000)*$efficiencyFactor)/2
$effectiveCapacity = "{0:N2}" -f $effectiveCapacity 
Write-Host "--------------------------------------------------------------------------------------------------------------"
Write-Host "Effective cluster capacity when filled to 100% (critical threshold): $effectiveCapacity TB"
Write-Host "Effective cluster capacity used on cluster: $effectiveUsed TB"
Write-Host "Effective cluster remaining until error threshold with deduplication/compression: $effectiveCapacityRemaining TB"
Write-Host "--------------------------------------------------------------------------------------------------------------"

