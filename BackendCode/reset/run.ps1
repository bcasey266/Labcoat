using namespace System.Net

# Input bindings are passed in via param block.
param($Request)

# Write to the Azure Functions log stream.
Write-Host "Received request to reset a Sandbox:"
$Request.Body

# Authenticate, if needed, and set context to Management Subscription
do {
    if (((Get-AzAccessToken).ExpiresOn) -lt (get-date)) {
        Write-Host "Token Expired. Re-authenticating."
        Connect-AzAccount -Identity -AccountId $env:ManagedIdentityClientID
    }

    Set-AzContext -SubscriptionId $env:SandboxManagementSubscription | Out-Null
} while (((Get-AzContext).Subscription.Id) -ne $env:SandboxManagementSubscription)


try {
    # Retrieve Sandbox Info from table
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
    $SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable
    $SandboxInfo = Get-AzTableRow -table $SandboxTable -ColumnName "RowKey" -Value $($Request.Body.SandboxName) -Operator Equal
    
    # Validate Sandbox and Request is authorized
    if ($SandboxInfo.Status -eq "Active") {
        if ($SandboxInfo.ObjectID -eq $Request.Body.ObjectID) {
            
            # Prep the Queue message
            $QueueMessage = @{
                "SandboxName" = $Sandbox.Rowkey
            }  | ConvertTo-Json

            #Add Message to Queue
            $EncodedMessage = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($QueueMessage))
            $StorageQueue = Get-AzStorageQueue -Name $env:StorageQueueResetSandbox -Context $StorageAccount.Context
            $StorageQueue.QueueClient.SendMessageAsync($EncodedMessage) | Out-Null

            # Return a Success Response
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                    StatusCode = [HttpStatusCode]::OK
                    Body       = "Sandbox Reset Request added to queue"
                })
        }
        else {
            # Return a Failure Response due to Sandbox not belonging to requestor
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                    StatusCode = [HttpStatusCode]::BadRequest
                    Body       = "Sandbox is not owned by you"
                })
        }
    }
    else {
        # Return a Failure Response due to Sandbox not being active
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body       = "Sandbox is not active and so it cannot be reset"
            })
    }
    
}
catch {
    # Return a Failure Response if any part of above failed
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = "Invalid information provided, please try again."
        })
}