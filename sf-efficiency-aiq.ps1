#UNOFFICIAL SCRIPT FOR CALCULATING SOLIDFIRE EFFICIENCIES

#       ====================================================================
#       Disclaimer: This script is written as best effort and provides no
#       warranty expressed or implied. Please contact the author(s) if you
#       have questions about this script before running or modifying
#       ====================================================================

$data = Read-Host "Enter all text from GetClusterFullThreshold API found in activeiq.solidfire.com"

$stage4BlockThresholdBytes = $data.Split('"stage4BlockThresholdBytes":')[-1]
[single]$stage4BlockThresholdBytes=$stage4BlockThresholdBytes.split(',')[0]
$stage5BlockThresholdBytes = $data.Split('"stage5BlockThresholdBytes":')[-1]
[single]$stage5BlockThresholdBytes=$stage5BlockThresholdBytes.split(',')[0]
$sumTotalClusterBytes = $data.Split('"sumTotalClusterBytes":')[-1]
[single]$sumTotalClusterBytes=$sumTotalClusterBytes.split(',')[0]


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

#CALCULATE FULL EFFICIENCY FACTOR FOR COMPRESSION + DEDUPLICATION + THIN PROVISIONING
$efficiencyFullFactor = ($deDuplicationFactor*$compressionFactor*$thinProvisioningFactor)

#GET THE CLUSTER ERROR THRESHOLD BYTES
$errorThresholdTB = ($stage4BlockThresholdBytes/1000/1000/1000/1000)

#GET CLUSTER CAPACITY AT ERROR THRESHOLD
$errorThresholdTotal = ($errorThresholdTB/2*.93*$efficiencyFactor)

#GET THE TOTAL USED RAW CAPACITY
$sumUsed = ($sumUsedClusterBytes/1000/1000/1000/1000)

#DETERMINE THE RAW SPACE AVAILABLE ON THE CLUSTER UNTIL ERROR THRESHOLD
$rawSpaceAvailableTB = (($stage4BlockThresholdBytes-$sumUsedClusterBytes)/(1000*1000*1000*1000))

#DETERMINE THE RAW SPACE AVAILABLE ON THE CLUSTER UNTIL 100% FULL
$rawSpaceAvailable100TB = (($stage5BlockThresholdBytes-$sumUsedClusterBytes)/(1000*1000*1000*1000))

#GET TOTAL CLUSTER CAPCITY
$sumTotalClusterBytes = ($sumTotalClusterBytes/1000/1000/1000/1000)

#GET CLUSTER FULL EFFECTIVE
$sumClusterFulldc = ($sumTotalClusterBytes*$efficiencyFactor)/2
$sumClusterFulldct = ($sumTotalClusterBytes*$efficiencyFullFactor)/2

#GET THE EFFECTIVE CAPACITY REMAINING OF COMPRESSION + DEDUPLICATION UNTIL ERROR THRESHOLD
$effectiveCapacityRemaining = ($rawSpaceAvailableTB*$efficiencyFactor)/2*.93

#GET THE EFFECTIVE CAPACITY OF COMPRESSION + DEDUPLICATION + THIN PROVISIONING UNTIL ERROR THRESHOLD
$effectiveFullCapacityRemaining = ($rawSpaceAvailableTB*$efficiencyFullFactor)/2

#GET THE EFFECTIVE CAPACITY REMAINING OF COMPRESSION + DEDUPLICATION UNTIL 100% FULL
$effectiveCapacityRemaining100 = ((($stage5BlockThresholdBytes-$sumUsedClusterBytes)*$efficiencyFactor)/(1000*1000*1000*1000))/2

#FORMAT TO 2 DECIMALS
$efficiencyFactor = "{0:N2}" -f $efficiencyFactor
$efficiencyFullFactor = "{0:N2}" -f $efficiencyFullFactor
$rawSpaceAvailableTB = "{0:N2}" -f $rawSpaceAvailableTB
$effectiveCapacity = "{0:N2}" -f $effectiveCapacity
$sumTotalClusterBytes = "{0:N2}" -f $sumTotalClusterBytes
$effectiveCapacityRemaining = "{0:N2}" -f $effectiveCapacityRemaining
$sumClusterFulldc = "{0:N2}" -f $sumClusterFulldc
$sumClusterFulldct = "{0:N2}" -f $sumClusterFulldct
$effectiveCapacityRemaining100 = "{0:N2}" -f $effectiveCapacityRemaining100
$sumUsed = "{0:N2}" -f $sumUsed
$errorThresholdTB = "{0:N2}" -f $errorThresholdTB
$compressionFactor = "{0:N2}" -f $compressionFactor
$deDuplicationFactor = "{0:N2}" -f $deDuplicationFactor
$thinProvisioningFactor = "{0:N2}" -f $thinProvisioningFactor
$rawSpaceAvailable100TB = "{0:N2}" -f $rawSpaceAvailable100TB
$effectiveFullCapacityRemaining = "{0:N2}" -f $effectiveFullCapacityRemaining
$errorThresholdTotal = "{0:N2}" -f $errorThresholdTotal

Write-Host "--------------------------------------------------------------------------------------------------------------"
#Write-Host "SolidFire Cluster: $clusterName"
#Write-Host ""
Write-Host "Cluster RAW Capacity: $sumTotalClusterBytes TB"
Write-Host "Cluster RAW Capacity Error Stage: $errorThresholdTB TB"
Write-Host "Cluster RAW Capacity Used: $sumUsed"
Write-Host "Cluster Error Stage RAW TB Remaining Available: $rawSpaceAvailableTB TB"
Write-Host "Cluster 100% Full RAW TB Remaining Available: $rawSpaceAvailable100TB TB"

Write-Host ""
Write-Host "Cluster Efficiencies"
#Write-Host "Thin Provisioning Ratio: $thinProvisioningFactor"
Write-Host "Deduplication Ratio: $deDuplicationFactor"
Write-Host "Compression Ratio: $compressionFactor"
Write-Host "Cluster Deduplication/Compression Efficiency: $efficiencyFactor"
#Write-host "Cluster Deduplication/Compression/Thin Provisioning Efficiency: $efficiencyFullFactor"
Write-Host ""
Write-Host "Cluster Critical 100% Full Capacity"
Write-Host "Cluster Effective Capacity @ 100% Full with Dedup/Comp: $sumClusterFulldc TB"
Write-Host "Effective Capacity Remaining until 100% Full with Dedup/Comp: $effectiveCapacityRemaining100 TB"

Write-Host ""
Write-Host "Cluster Critical Error Threshold Capacity"
Write-Host "Cluster Effective Capacity @ Error Threshold with Dedup/Comp: $errorThresholdTotal TB"
Write-Host "Effective Capacity Remaining until Error Threshold with Dedup/Comp: $effectiveCapacityRemaining TB"
Write-Host "--------------------------------------------------------------------------------------------------------------"
