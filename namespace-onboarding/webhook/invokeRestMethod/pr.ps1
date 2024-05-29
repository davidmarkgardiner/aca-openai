# Define parameters for the script
Param(
    [String]$branch,  # The name of the branch to checkout from
    [String]$newBranch,  # The name of the new branch to create
    [String]$commitMessage,  # The commit message to use
    [String]$gitUsername = "Subscription Automation",  # The Git username
    [String]$Repo = "uk8s-cluster-config"  # The name of the repository
)

# Import the Az.Accounts module
import-module Az.Accounts

# Print the current location
Write-Host 
Get-Location

# Print the build source directory
echo "$env:build_SOURCESDIRECTORY"

# Print the current directory and its contents
pwd
ls

# Change to the parent directory
cd ..

# Print the current directory and its contents
pwd
ls

# Get the current location and set it as the working directory
$path = Get-Location
Set-Location $path\

# Configure the global Git user email and username
git config --global user.email dl-public-cloud-eng@ubs.com
git config --global user.name $gitUsername

# Checkout the specified branch and create a new branch
git checkout "origin/$branch"
git checkout -b $newBranch

# Stage all changes, commit them, and push the new branch to the remote repository
git add .
git commit -q -m $commitMessage
git push -u origin $newBranch

# Define the URI for the Azure DevOps API
$uri = https://dev.azure.com/UBS-Cloud/UBSCloudPlatform/_apis/git/repositories/uk8s-cluster-config/pullrequests?api-version=7.1-preview.1

# Define the authorization header for the API request
$authHeader = @{
    'Authorization' = 'Bearer ' + (Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798").Token
    'Content-Type'  = 'application/json'
}

# Define the pull request details
$pullRequest = @{
    "sourceRefName" = "refs/heads/$newBranch"
    "targetRefName" = "refs/heads/$branch"
    "title"         = "Pull from $newBranch to $branch"
    "description"   = $commitMessage
}

# Convert the pull request details to JSON
$pullRequestJson = ($pullRequest | ConvertTo-Json -Depth 100)

# Print a message indicating that a REST call is being made
Write-Output "Sending a REST call to create a new pull request from develop to master"

# Make the REST call to create the pull request
try {
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $pullRequestJson -ContentType "application/json" -Headers $authHeader
    $StatusCode = $Response.StatusCode
}
catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
}

# Print the status code
$StatusCode

# If the status code is 200, print a success message and the response
if ($StatusCode -eq 200) {
    Write-Output "Pull request created"
    $response
}