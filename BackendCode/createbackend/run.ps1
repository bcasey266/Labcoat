# Input bindings are passed in via param block.
param($QueueItem, $TriggerMetadata)

$FirstName = $QueueItem.FirstName
$LastName = $QueueItem.LastName
$Email = $QueueItem.Email
$ManagerEmail = $QueueItem.ManagerEmail
$Budget = $QueueItem.Budget
$Length = $QueueItem.Length
$CostCenter = $QueueItem.CostCenter

# Configure Storage Account Connection
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName

#Gets increment counter number from Azure Table
$CounterTable = (Get-AzStorageTable -Name $env:StorageTableCounter -Context $StorageAccount.Context).CloudTable
$CounterRow = Get-AzTableRow -table $CounterTable 

try {
    $CounterRow.Counter = ++$CounterRow.Counter
    $CounterRow | Update-AzTableRow -table $CounterTable | Out-Null
    $Counter = $CounterRow.Counter
}
catch {
    Add-AzTableRow -Table $CounterTable -PartitionKey "Sandbox" -RowKey "Number" -Property @{ "Counter" = 2 }
    $Counter = 1
}

#Necessary Variables
#TODO: Switch counter to be user specific
$SandboxName = "Sandbox-" + $FirstName + "-" + $LastName + "-" + $Counter
$SandboxSubscriptionID = $env:SandboxSubscription

#Sandbox Resource Group Creation
Write-Information "Creating Sandbox Resource Group.  Name: $SandboxName"

Set-AzContext -SubscriptionId $env:SandboxSubscription | Out-Null
$tags = @{"SandboxOwner" = $Email; "Environment" = "Sandbox"; "CostCenter" = $CostCenter }
$NewSandboxRG = New-AzResourceGroup -Name $SandboxName -Tag $tags -Location "East US" #TODO: Allow different regions

Write-Information "Sandbox Resource Group Created Successfully"

#TODO: Add RBAC
<#
#Authenticating to AzureAD
$AzureADBody = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$AzureADBody.Add("tenant", $AzureTenantId)
$AzureADBody.Add("client_id", $ClientId)
$AzureADBody.Add("client_secret", $SecretText)
$AzureADBody.Add("grant_type", "client_credentials")
$AzureADBody.Add("scope", "https://graph.microsoft.com/.default")
$AzureADLogin = Invoke-RestMethod "https://login.microsoftonline.com/$AzureTenantId/oauth2/v2.0/token" -Method 'POST' -Body $AzureADBody
connect-MgGraph -AccessToken $AzureADLogin.access_token

#Retrieving Requestor's ObjectID
$AzureADUser = get-mgUser -Search "Mail:$Email" -ConsistencyLevel eventual

if ($null -eq $AzureADUser) {
    $AzureADUser = get-mgUser -Search "UserPrincipalName:$Email" -ConsistencyLevel eventual
}

#Assigns Creator as Owner
New-AzRoleAssignment -ObjectId $AzureADUser.Id -RoleDefinitionName "Owner" -Scope "/subscriptions/$($NewSubscription.Properties.SubscriptionId)" | Out-Null

Write-Information "$FirstName $LastName has been added as an Owner on the Sandbox"
#>

#SETTING CLOUD TABLE CONTEXT
$SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable


#ADDING NEW ROW TO TABLE
$enddate = (Get-Date).AddDays([int]$Length).ToString("yyyy-MM-dd") 
Add-AzTableRow -Table $SandboxTable -PartitionKey "Sandbox" -RowKey $SandboxName -Property @{
    "SandboxName"  = $SandboxName
    "User"         = $Email
    "ManagerEmail" = $ManagerEmail
    "CreationDate" = (Get-Date).ToString("yyyy-MM-dd")
    "EndDate"      = $enddate
    "Status"       = "Active"
    "Budget"       = $Budget
    "CostCenter"   = $CostCenter
} | Out-Null

Write-Information "Sandbox has been created!"