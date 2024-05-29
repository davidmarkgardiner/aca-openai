# Create authorization headers using Azure DevOps Personal Access Token (PAT)
$ADOToken = 'xxx'
$ADOAuthHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($ADOToken)"))
$GetHeaders = @{'Authorization' = 'Basic ' + $ADOAuthHeader;  'Content-Type'='application/json'}

# Define the source CSV file and the result CSV file
$SourceFile = 'C:\Users\t588486\Downloads\PEtestrun.csv'
$ResultFile = 'C:\Users\t588486\Downloads\PEtestrun_results.csv'

# Import the CSV file into a PowerShell object
$ExemptionList = Import-CSV -Path $SourceFile
$BuildResults = @()
$BuildIdList = @()

$i=1
# Loop through each exemption in the list
foreach($e in $ExemptionList){
    # Output the details of the current exemption
    Write-Output "Policy: $($e.PolicyName), scope: $($e.Scope), expiration date: $($e.ExpirationDate),`nRequestor: $($e.Requestor), request id: $($e.RequestId)  ($i/$($ExemptionList.count))"

    # Define the body of the POST request to run the pipeline
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

    # Define the URL to run the pipeline
    $PipelineRunUrl = https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/pipelines/782/runs?api-version=6.0-preview.1

    # Send the POST request to run the pipeline
    $PipelineRunRequest = Invoke-RestMethod -Method Post -Uri $PipelineRunUrl -Body $body -Headers $GetHeaders

    # Add the ID of the pipeline run to the list
    $BuildIdList += $PipelineRunRequest.id

    $i++
    # Wait for 20 seconds before the next iteration
    Start-Sleep 20
}

# Collect the results of the pipeline runs
Write-Output "Collecting pipeline runs data"
$i=1
do{
    Write-Output "Attempt $i"
    # Wait for 1 minute before the next attempt
    Start-Sleep 60

    $InProgressIds = @()
    foreach($id in $BuildIdList){
        # Get the status of the pipeline run
        $BuildStatusUrl = https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/build/builds/${id}?api-version=6.0
        $BuildStatusRequest = Invoke-RestMethod -Method Get -Uri $BuildStatusUrl -Headers $GetHeaders

        if($($BuildStatusRequest.status) -eq 'completed'){
            # If the pipeline run is completed, get the timeline of the run
            $BuildTimelineUrl = https://dev.azure.com/UBS-CLOUD/UBSCloudPlatform/_apis/build/builds/${id}/Timeline?api-version=6.0
            $BuildTimelineRequest = Invoke-RestMethod -Method Get -Uri $BuildTimelineUrl -Headers $GetHeaders

            # Collect the issues from the timeline
            $IssuesString = ''
            $BuildTimelineRequest.records.issues | Where-Object {$_.message -ne $null} | ForEach-Object {$IssuesString += "$($_.type) :: $($_.message)`n"}

            # Add the result of the pipeline run to the list
            $BuildResults += $BuildStatusRequest | Select-Object id,buildNumber,queueTime,startTime,finishTime,status,result,@{label='Scope';expression={$_.templateParameters.scope}},`
            @{label='PolicyName';expression={$_.templateParameters.policyName}},@{label='RequestId';expression={$_.templateParameters.requestId}},`
            @{label='Requestor';expression={$_.templateParameters.requestor}},@{label='ExpirationDate';expression={$_.templateParameters.expirationDate}},@{label='Issues';expression={$IssuesString}}
        }
        else{
            # If the pipeline run is not completed, add its ID to the list
            $InProgressIds += $BuildStatusRequest.id
        }
    }

    $BuildIdList = $InProgressIds
    $i++
} while($BuildIdList.length -gt 0)

# Export the results to a CSV file
$BuildResults | Export-Csv -Path $ResultFile -NoTypeInformation

Write-Output 'Completed.'