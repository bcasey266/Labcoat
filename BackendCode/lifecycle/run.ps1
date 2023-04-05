# Input bindings are passed in via param block.
param($Timer)

#Keyvault
#$budgetsecret = Get-AzKeyVaultSecret -VaultName "" -Name "" -Asplaintext
#$deactivatesecret = Get-AzKeyVaultSecret -VaultName "" -Name "" -Asplaintext


# Setup REST Calls
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Bearer $((Get-AzAccessToken).Token)")

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()


$StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
$SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable
$ActiveSandboxes = Get-AzTableRow -table $SandboxTable -columnName "Status" -Value "Active" -Operator Equal

foreach ($Sandbox in $ActiveSandboxes) { 
    Write-Host "CHECKING SUBSCRIPTION"
    Write-Host $Sandbox.Rowkey
    
    $body = @{
        "type"       = "ActualCost"
        "timeframe"  = "Custom"
        "timePeriod" = @{
            "from" = ([datetime]$Sandbox.CreationDate).AddDays(-1)
            "to"   = $Sandbox.EndDate        
        }
        "dataSet"    = @{
            "granularity" = "None"
            "aggregation" = @{
                "totalCost" = @{
                    "name"     = "Cost"
                    "function" = "Sum"
                }
            }
        }
    }
    
    $SandboxCost = [math]::Round((Invoke-RestMethod "https://management.azure.com/subscriptions/$env:SandboxSubscription/resourceGroups/$($Sandbox.Rowkey)/providers/Microsoft.CostManagement/query?api-version=2021-10-01" -Method 'POST' -Headers $headers -Body ($body | ConvertTo-Json -Depth 100) -ContentType "application/json").properties.rows[0][0], 2)


    # TODO: build in cost notifications
    <#
    # LOGIC APP TO EMAIL USER / MANAGER - "AZURE2HELP"

    $body = @{
        "currentCost" = "$" + [math]::Round($currentCost.Sum, 2)
        "SubOwner"    = $SubOwner
        "SubId"       = $rowkey
        "SubName"     = $subName
    }
    Invoke-RestMethod -uri ""
#>

    # CANCEL THE SUBSCRIPTION     
    if ($SandboxCost -ge $($Sandbox.Budget) -or $($Sandbox.EndDate) -le (Get-Date)) {
        $QueueMessage = @{
            "SandboxName" = $Sandbox.Rowkey
        }  | ConvertTo-Json

        $EncodedMessage = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($QueueMessage))

        #Add Message to Queue
        $StorageQueue = Get-AzStorageQueue -Name $env:StorageQueueDeleteSandbox -Context $StorageAccount.Context
        $StorageQueue.QueueClient.SendMessageAsync($EncodedMessage)
    }
} 

