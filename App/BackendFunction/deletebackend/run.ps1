using namespace System.Net

# Input bindings are passed in via param block.
param($QueueItem)

Write-Host "Deleting Sandbox $($QueueItem.SandboxName)"

do {
    if (((Get-AzAccessToken).ExpiresOn) -lt (get-date)) {
        Write-Host "Token Expired. Re-authenticating."
        Connect-AzAccount -Identity -AccountId $env:ManagedIdentityClientID
    }

    Set-AzContext -SubscriptionId $env:SandboxSubscription | Out-Null
} while (((Get-AzContext).Subscription.Id) -ne $env:SandboxSubscription)

# Retrieve Resource Group and delete it
Get-AzResourceGroup -Name $($QueueItem.SandboxName) | Remove-AzResourceGroup -Force

# Update Table to mark Sandbox as deleted
Set-AzContext -SubscriptionId $env:SandboxManagementSubscription | Out-Null
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
$SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable
$DeletedSandbox = Get-AzTableRow -table $SandboxTable -ColumnName "RowKey" -Value $($QueueItem.SandboxName) -Operator Equal
$DeletedSandbox.Status = "Deleted"
$DeletedSandbox | Update-AzTableRow -Table $SandboxTable

# Send a Notification if notifications have been enabled
if ($env:NotificationsEnabled -eq "true") {
    # Prep the Queue message
    $QueueMessage = @{
        "NotificationType" = "Delete"
        "FirstName"        = $DeletedSandbox.FirstName
        "Email"            = $DeletedSandbox.User
        "SandboxName"      = $QueueItem.SandboxName
        "DeletionReason"   = $QueueItem.DeletionReason
    } | ConvertTo-Json

    #Add Message to Queue
    $EncodedMessage = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($QueueMessage))
    $StorageQueue = Get-AzStorageQueue -Name $env:StorageQueueNotifications -Context $StorageAccount.Context
    $StorageQueue.QueueClient.SendMessageAsync($EncodedMessage) | Out-Null
}

Write-Information "$($QueueItem.SandboxName) has been deleted!"
