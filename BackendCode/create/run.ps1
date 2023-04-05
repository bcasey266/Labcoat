using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Get-AzAccessToken

# Write to the Azure Functions log stream.
Write-Host "Received request to create a new Sandbox:"
$Request.Body

$QueueMessage = @{
    "FirstName"    = $Request.Body.FirstName
    "LastName"     = $Request.Body.LastName
    "Email"        = $Request.Body.Email
    "ManagerEmail" = $Request.Body.ManagerEmail
    "Budget"       = $Request.Body.Budget
    "Length"       = $Request.Body.Length
    "CostCenter"   = $Request.Body.CostCenter
} | ConvertTo-Json

$EncodedMessage = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($QueueMessage))

#Add Message to Queue
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
$StorageQueue = Get-AzStorageQueue -Name $env:StorageQueueNewSandbox -Context $StorageAccount.Context
$StorageQueue.QueueClient.SendMessageAsync($EncodedMessage)

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
