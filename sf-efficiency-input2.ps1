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

[single]$sumUsedClusterBytes = Read-Host "Enter sumUsedClusterBytes from GetClusterFullThreshold API"
[single]$stage4BlockThresholdBytes = Read-Host "Enter stage4BlockThresholdBytes from GetClusterFullThreshold API"
[single]$efficiencyFactor = Read-Host "Enter Efficiency Factor Compression*Deduplication ratio API"
[single]$effectiveCapacity = Read-Host "Enter sumTotalClusterBytes from GetClusterFullThreshold API"
$effectiveCapacityRemaining =((($stage4BlockThresholdBytes - $sumUsedClusterBytes)/(1000*1000*1000*1000))*$efficiencyFactor)/2
$effectiveCapacityRemaining = "{0:N2}" -f $effectiveCapacityRemaining
$effectiveUsed = ($sumUsedClusterBytes/(1000*1000*1000*1000)*$efficiencyFactor)
$effectiveUsed = "{0:N2}" -f $effectiveUsed
$effectiveCapacity = $effectiveCapacity/(1000*1000*1000*1000)
$effectiveCapacity = "{0:N2}" -f $effectiveCapacity 
Write-Host "--------------------------------------------------------------------------------------------------------------"
Write-Host "Effective Cluster Capacity: $effectiveCapacity TB"
Write-Host "Effective Capacity: $effectiveUsed TB"
Write-Host "Effective Capacity Remaining until Error Threshold with Dedup/Comp: $effectiveCapacityRemaining TB"
Write-Host "--------------------------------------------------------------------------------------------------------------"

