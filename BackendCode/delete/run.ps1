using namespace System.Net

# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

Write-Host "Deleting Sandbox $($QueueItem.SandboxName)"

$ManagementSubscription = (Get-AzContext).Subscription.Id

Set-AzContext -SubscriptionId $env:SandboxSubscription

Get-AzResourceGroup -Name $($QueueItem.SandboxName) | Remove-AzResourceGroup -Force

# Update Table to mark Sandbox as deleted
Set-AzContext -SubscriptionId $ManagementSubscription

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
$SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable

$DeletedSandbox = Get-AzTableRow -table $SandboxTable -RowKey $($QueueItem.SandboxName)

$DeletedSandbox.Status = "Deleted"
$DeletedSandbox | Update-AzTableRow -Table $SandboxTable