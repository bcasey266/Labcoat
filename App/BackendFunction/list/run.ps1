using namespace System.Net

# Input bindings are passed in via param block.
param($Request)

# Write to the Azure Functions log stream.
Write-Host "Received request to retrieve all sandboxes for user"
$Request.Query

# Authenticate, if needed, and set context to Management Subscription
do {
    if (((Get-AzAccessToken).ExpiresOn) -lt (get-date)) {
        Write-Host "Token Expired. Re-authenticating."
        Connect-AzAccount -Identity -AccountId $env:ManagedIdentityClientID
    }

    Set-AzContext -SubscriptionId $env:SandboxManagementSubscription | Out-Null
} while (((Get-AzContext).Subscription.Id) -ne $env:SandboxManagementSubscription)


try {
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
    $SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable
    $UserSandboxes = Get-AzTableRow -table $SandboxTable -columnName "ObjectID" -Value $Request.Query.ObjectID -Operator Equal

    # Return a Success Response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $UserSandboxes | Select-Object "RowKey", "ManagerEmail", "Budget", "CostCenter", "EndDate", "Status" | ConvertTo-Json
        })
}
catch {
    # Return a Failure Response if any part of above failed
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = "Unable to retrive Sandbox list"
        })
}