#UNOFFICIAL SCRIPT FOR CALCULATING SOLIDFIRE EFFICIENCIES

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

[single]$stage4BlockThresholdBytes = Read-Host "Enter stage4BlockThresholdBytes from GetClusterFullThreshold"
[single]$sumUsedClusterBytes = Read-Host "Enter sumUsedClusterBytes from GetClusterFullThreshold"
[single]$efficiencyFactor = Read-Host "Enter Efficiency Factor Compression*Deduplication ratio"
$effectiveCapacityRemaining =((($stage4BlockThresholdBytes - $sumUsedClusterBytes)/(1000*1000*1000*1000))*$efficiencyFactor)/2
$effectiveCapacityRemaining = "{0:N2}" -f $effectiveCapacityRemaining
Write-Host "--------------------------------------------------------------------------------------------------------------"
Write-Host "Effective Capacity Remaining until Error Threshold with Dedup/Comp: $effectiveCapacityRemaining TB"
Write-Host "--------------------------------------------------------------------------------------------------------------"

