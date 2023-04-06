# Input bindings are passed in via param block.
param($Timer)

function Get-Cost {
    param (
        [string]$ResourceGroupName
    )

    # This setups the JSON body needed to make the REST API call to Azure's Cost Management
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


    $done = $false

    # This performs the action of retrieving the cost from Azure's Cost Management.  Due to rate limiting, a retry method was built into the block of code
    while ($done -ne $true) {
        try {
            $SandboxCostResponse = Invoke-RestMethod "https://management.azure.com/subscriptions/$env:SandboxSubscription/resourceGroups/$($Sandbox.Rowkey)/providers/Microsoft.CostManagement/query?api-version=2021-10-01" -Method 'POST' -Headers $headers -Body ($body | ConvertTo-Json -Depth 100) -ContentType "application/json"

            $done = $true
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            if ($_.Exception.Response.StatusCode -eq 429) {
                $delay = 1000
                Write-Verbose -Message "Retry Caught, delaying $delay ms"
                Start-Sleep -Milliseconds $delay
            }
            else {
                "Unknown Error"
                $done = $true
            }
        }
        catch {
            "Unknown Error"
            $done = $true
        }
    }

    try {
        $SandboxCost = [math]::Round($SandboxCostResponse.properties.rows[0][0], 2)
    }
    catch {
        $SandboxCost = 0
    }

    return $SandboxCost
}

if (((Get-AzAccessToken).ExpiresOn) -lt (get-date)) {
    Write-Host "Token Expired. Re-authenticating."
    Connect-AzAccount -Identity -AccountId $env:ManagedIdentityClientID
}

Set-AzContext -SubscriptionId $env:SandboxManagementSubscription | Out-Null

# Setup REST Calls
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")
$headers.Add("Authorization", "Bearer $((Get-AzAccessToken).Token)")

$StorageAccount = Get-AzStorageAccount -ResourceGroupName $env:ResourceGroupName -Name $env:StorageAccountName
$SandboxTable = (Get-AzStorageTable -Name $env:StorageTableSandbox -Context $StorageAccount.Context).CloudTable
$ActiveSandboxes = Get-AzTableRow -table $SandboxTable -columnName "Status" -Value "Active" -Operator Equal

foreach ($Sandbox in $ActiveSandboxes) {
    Set-AzContext -SubscriptionId $env:SandboxSubscription | Out-Null 
    Write-Host "CHECKING SUBSCRIPTION"
    Write-Host $Sandbox.Rowkey
    
    $SandboxCost = Get-Cost -ResourceGroupName $Sandbox.Rowkey

    foreach ($ChildResource in (Get-AzResource -ResourceGroupName $Sandbox.Rowkey | Where-Object "ResourceType" -in ("Microsoft.ContainerService/managedClusters", "Microsoft.Databricks/workspaces", "Microsoft.Purview/accounts"))) {
        switch ($ChildResource.ResourceType) {
            Microsoft.ContainerService/managedClusters {
                $ResourceCost = Get-Cost -ResourceGroupName (Get-AzAksCluster -Name $ChildResource.Name -ResourceGroupName $ChildResource.ResourceGroupName).NodeResourceGroup
                $SandboxCost += $ResourceCost
            }
            Microsoft.Databricks/workspaces {
                $ResourceCost = Get-Cost -ResourceGroupName ((Get-AzDatabricksWorkspace -Name $result[1].name -ResourceGroupName $result[1].ResourceGroupName).ManagedResourceGroupId).Split("/")[4]
                $SandboxCost += $ResourceCost
            }
            Microsoft.Purview/accounts {
                $ResourceCost = Get-Cost -ResourceGroupName ((Get-AzPurviewAccount -Name $ChildResource.Name -ResourceGroupName $ChildResource.ResourceGroupName).ManagedResourceGroupId)
                $SandboxCost += $ResourceCost
            }
            Default {}
        }
    }

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
    if ($SandboxCost -ge $($Sandbox.Budget) -or [datetime]$($Sandbox.EndDate) -le (Get-Date)) {
        Set-AzContext -SubscriptionId $env:SandboxManagementSubscription | Out-Null
        $QueueMessage = @{
            "SandboxName" = $Sandbox.Rowkey
        }  | ConvertTo-Json

        $EncodedMessage = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($QueueMessage))

        #Add Message to Queue
        $StorageQueue = Get-AzStorageQueue -Name $env:StorageQueueDeleteSandbox -Context $StorageAccount.Context
        $StorageQueue.QueueClient.SendMessageAsync($EncodedMessage)
    }
} 

