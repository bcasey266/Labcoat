using namespace System.Net

# Input bindings are passed in via param block.
param($Request)

# Write to the Azure Functions log stream.
Write-Host "Received request to create a new Sandbox:"
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
    # Query Azure AD for User information
    $ADUserInfo = Get-AzADUser -ObjectId $Request.Body.ObjectID -ErrorAction Stop

    # Prep the Queue message while removing non-standard characters
    $QueueMessage = @{
        "FirstName"    = $ADUserInfo.GivenName -replace '[^a-zA-Z0-9]', ''
        "LastName"     = $ADUserInfo.Surname -replace '[^a-zA-Z0-9]', ''
        "Email"        = $ADUserInfo.Mail
        "ObjectID"     = $Request.Body.ObjectID
        "ManagerEmail" = $Request.Body.ManagerEmail
        "Budget"       = $Request.Body.Budget
        "Length"       = $Request.Body.Length
        "CostCenter"   = $Request.Body.CostCenter
    } | ConvertTo-Json

    #Add Message to Queue
    $EncodedMessage = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($QueueMessage))
    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
    $StorageQueue = Get-AzStorageQueue -Name $env:StorageQueueNewSandbox -Context $StorageAccount.Context
    $StorageQueue.QueueClient.SendMessageAsync($EncodedMessage) | Out-Null

    # Return a Success Response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = "Sandbox Creation request added to queue"
        })
}
catch {
    # Return a Failure Response if any part of above failed
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Body       = "Invalid information provided, please try again."
        })
}