## Create token for UBSPlatform org

## Create authorization headers using ADO PAT token

$ADOToken = 'xxx'

$ADOAuthHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($ADOToken)"))

$GetHeaders = @{'Authorization' = 'Basic ' + $ADOAuthHeader;  'Content-Type'='application/json'}

 

## Update path for source and destination

$SourceFile = 'C:\Users\t588486\Downloads\PEtestrun.csv'

$ResultFile = 'C:\Users\t588486\Downloads\PEtestrun_results.csv'

 

$ExemptionList = Import-CSV -Path $SourceFile

$BuildResults = @()

$BuildIdList = @()

 

$i=1

foreach($e in $ExemptionList){

 

    Write-Output "Policy: $($e.PolicyName), scope: $($e.Scope), expiration date: $($e.ExpirationDate),`nRequestor: $($e.Requestor), request id: $($e.RequestId)  ($i/$($ExemptionList.count))"

#Request parameters

$body = @"

{

    "resources": {

        "repositories": {

            "self": {

                "refName": "refs/heads/master"

            }

        }

    },

    "templateParameters": {

        "scope":"$($e.Scope)",

        "policyName":"$($e.PolicyName)",

        "RequestId":"$($e.RequestId)",

        "taskId":"$($e.TaskId)",

        "requestor":"$($e.Requestor)",

        "expirationDate":"$($e.ExpirationDate)",

        "CDAApproval":"$($e.CDAApproval)",

        "tenant":"$($e.Tenant)",

        "sendMail":"false"

    }

}

"@

 

    ## Pipeline URL, 782 is policy exemption pipeline ID

    $PipelineRunUrl = https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/pipelines/782/runs?api-version=6.0-preview.1

    $PipelineRunRequest = Invoke-RestMethod -Method Post -Uri $PipelineRunUrl -Body $body -Headers $GetHeaders

    $PipelineRunRequest.name

 

    $BuildIdList += $PipelineRunRequest.id

    $i++

    Start-Sleep 20

}

 

Write-Output "Collecting pipeline runs data"

$i=1

do{

    Write-Output "Attempt $i"

    # Wait 1 minute to complete ongoing builds

    Start-Sleep 60

 

    $InProgressIds = @()

    foreach($id in $BuildIdList){

 

 

        $BuildStatusUrl = https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/build/builds/${id}?api-version=6.0

        $BuildStatusRequest = Invoke-RestMethod -Method Get -Uri $BuildStatusUrl -Headers $GetHeaders

        if($($BuildStatusRequest.status) -eq 'completed'){

 

            $BuildTimelineUrl = https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/build/builds/${id}/Timeline?api-version=6.0

            $BuildTimelineRequest = Invoke-RestMethod -Method Get -Uri $BuildTimelineUrl -Headers $GetHeaders

 

            $IssuesString = ''

            $BuildTimelineRequest.records.issues | Where-Object {$_.message -ne $null} | ForEach-Object {$IssuesString += "$($_.type) :: $($_.message)`n"}

 

            $BuildResults += $BuildStatusRequest | Select-Object id,buildNumber,queueTime,startTime,finishTime,status,result,@{label='Scope';expression={$_.templateParameters.scope}},`

            @{label='PolicyName';expression={$_.templateParameters.policyName}},@{label='RequestId';expression={$_.templateParameters.requestId}},`

            @{label='Requestor';expression={$_.templateParameters.requestor}},@{label='ExpirationDate';expression={$_.templateParameters.expirationDate}},@{label='Issues';expression={$IssuesString}}

        }

        else{

            $InProgressIds += $BuildStatusRequest.id

        }

    }

 

    $BuildIdList = $InProgressIds

    $i++

 

     

} while($BuildIdList.length -gt 0)

 

$BuildResults | Export-Csv -Path $ResultFile -NoTypeInformation

 

Write-Output 'Completed.'