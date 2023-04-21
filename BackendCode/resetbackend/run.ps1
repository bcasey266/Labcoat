using namespace System.Net

# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

Write-Host "Resetting Sandbox $($QueueItem.SandboxName)"

if (((Get-AzAccessToken).ExpiresOn) -lt (get-date)) {
    Write-Host "Token Expired. Re-authenticating."
    Connect-AzAccount -Identity -AccountId $env:ManagedIdentityClientID
}

Set-AzContext -SubscriptionId $env:SandboxSubscription | Out-Null

# Get the initial list of resources in the Sandbox
$ResourceList = Get-AzResource -ResourceGroupName $QueueItem.SandboxName
$Retry = 0
$RetryLimit = 5

# Attempts to delete each resource in the Sandbox. Retry is necessary due to resource dependencies
do {
    $i = 1

    # Starts deletion of every resource as background job and then waits
    foreach ($Resource in $ResourceList) {
        Write-Host "Deleting Resource $i of $($ResourceList.Length)"
        Remove-AzResource -ResourceId $Resource.ResourceId -Force -AsJob | Out-Null
        $i++
    }
    Get-Job | Wait-Job | Out-Null

    # Sleeps until it checks if resources still exist
    Start-Sleep 30
    $ResourceList = Get-AzResource -ResourceGroupName $QueueItem.SandboxName

    if ($null -ne $ResourceList) {
        $Retry++
        if ($Retry -le $RetryLimit) {
            Write-Host "Failed to Delete: `n `n  $($ResourceList.Name) `n `n Retrying Deletion... $Retry of $RetryLimit"
            Write-Host "-----------------------------------------------------------------------------------------------"
        }
    }
} while (
    $null -ne $ResourceList -and $Retry -le $RetryLimit
)

# Update Table to mark Sandbox as Active
Set-AzContext -SubscriptionId $env:SandboxManagementSubscription | Out-Null

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
$SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable

$ResetSandbox = Get-AzTableRow -table $SandboxTable -ColumnName "RowKey" -Value $($QueueItem.SandboxName) -Operator Equal

$ResetSandbox.Status = "Active"
$ResetSandbox | Update-AzTableRow -Table $SandboxTable