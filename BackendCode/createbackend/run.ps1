# Input bindings are passed in via param block.
param($QueueItem)

# Authenticate, if needed, and set context to Management Subscription
do {
    if (((Get-AzAccessToken).ExpiresOn) -lt (get-date)) {
        Write-Host "Token Expired. Re-authenticating."
        Connect-AzAccount -Identity -AccountId $env:ManagedIdentityClientID
    }

    Set-AzContext -SubscriptionId $env:SandboxManagementSubscription | Out-Null
} while (((Get-AzContext).Subscription.Id) -ne $env:SandboxManagementSubscription)

$ErrorActionPreference = 'Stop'
try {
    # Configure Storage Account Connection
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
    $SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable

    # Get total number of sandboxes for user and create Sandbox name based on that
    $UserSandboxCount = Get-AzTableRow -table $SandboxTable -ColumnName "ObjectID" -Value $QueueItem.ObjectID -Operator Equal
    $SandboxName = "Sandbox-" + $QueueItem.FirstName + "-" + $QueueItem.LastName + "-" + $($UserSandboxCount.Count + 1)

    # Create Sandbox Resource Group
    Write-Information "Creating Sandbox Resource Group.  Name: $SandboxName"
    Set-AzContext -SubscriptionId $env:SandboxSubscription | Out-Null
    $tags = @{"SandboxOwner" = $QueueItem.Email; "Environment" = "Sandbox"; "CostCenter" = $QueueItem.CostCenter }
    New-AzResourceGroup -Name $SandboxName -Tag $tags -Location "East US"

    # Assign Sandbox Requestor as Owner
    New-AzRoleAssignment -ObjectId $QueueItem.ObjectID -RoleDefinitionName "Owner" -ResourceGroupName $SandboxName | Out-Null
    Write-Information "$($QueueItem.FirstName) $($QueueItem.LastName) has been added as an Owner on the Sandbox"

    # Adds new Sandbox to Azure Table
    Add-AzTableRow -Table $SandboxTable -PartitionKey "Sandbox" -RowKey $SandboxName -Property @{
        "FirstName"    = $QueueItem.FirstName
        "LastName"     = $QueueItem.LastName
        "User"         = $QueueItem.Email
        "ObjectID"     = $QueueItem.ObjectID
        "ManagerEmail" = $QueueItem.ManagerEmail
        "CreationDate" = (Get-Date).ToString("yyyy-MM-dd")
        "EndDate"      = (Get-Date).AddDays([int]$QueueItem.Length).ToString("yyyy-MM-dd")
        "Status"       = "Active"
        "Budget"       = $QueueItem.Budget
        "CostCenter"   = $QueueItem.CostCenter
    } | Out-Null

    # Prep the Queue message
    $QueueMessage = @{
        "NotificationType" = "New"
        "FirstName"        = $QueueItem.FirstName
        "LastName"         = $QueueItem.LastName
        "Email"            = $QueueItem.Email
        "SandboxName"      = $SandboxName
        "Budget"           = "{0:C0}" -f [int]$QueueItem.Budget
        "DeleteOn"         = (Get-Date).AddDays([int]$QueueItem.Length).ToString("yyyy-MM-dd")
    } | ConvertTo-Json

    #Add Message to Queue
    $EncodedMessage = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($QueueMessage))
    $StorageQueue = Get-AzStorageQueue -Name $env:StorageQueueNotifications -Context $StorageAccount.Context
    $StorageQueue.QueueClient.SendMessageAsync($EncodedMessage) | Out-Null

    Write-Information "Sandbox has been created!"
}
catch {
    Write-Error "$SandboxName was unable to be created: $($error[0].Exception.Message)"
}
