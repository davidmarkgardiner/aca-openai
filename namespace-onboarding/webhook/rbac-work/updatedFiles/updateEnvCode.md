## Useful code to remmove dependany on .env file.

To remove the dependency on the `.env` file while breaking out the `aksclusterresourceid` into variables, you can follow these steps. The goal is to extract the `clustername`, `subscription`, and `resource group` from the `aksclusterresourceid` and pass them as variables in your pipeline without needing an external `.env` file.

### Steps to Implement

#### 1. **Extract Variables from `aksclusterresourceid`**
The `aksclusterresourceid` format is structured like this:
```
subscription/12345678/resourceGroups/rgname/providers/Microsoft.ContainerService/managedClusters/clustername
```
We can parse it into:
- `subscription`: The value after `subscription/` and before `/resourceGroups/`
- `resource group (rg)`: The value after `resourceGroups/` and before `/providers/`
- `clustername`: The value after `managedClusters/`

You can use a script to extract these values.

#### 2. **Define the `aksclusterresourceid` as a Pipeline Variable**
In your pipeline definition (e.g., in YAML for Azure Pipelines or GitLab CI/CD), you can pass the `aksclusterresourceid` as a parameter or variable. Here’s an example:

```yaml
variables:
  aksclusterresourceid: "subscription/12345678/resourceGroups/rgname/providers/Microsoft.ContainerService/managedClusters/clustername"

# You can use script steps to parse the values
steps:
- script: |
    echo "Parsing the aksclusterresourceid..."
    # Extract subscription ID
    SUB=$(echo $(aksclusterresourceid) | cut -d '/' -f 2)
    # Extract resource group
    RG=$(echo $(aksclusterresourceid) | cut -d '/' -f 4)
    # Extract cluster name
    CLUSTERNAME=$(echo $(aksclusterresourceid) | rev | cut -d '/' -f 1 | rev)
    echo "##vso[task.setvariable variable=sub]$SUB"
    echo "##vso[task.setvariable variable=rg]$RG"
    echo "##vso[task.setvariable variable=clustername]$CLUSTERNAME"
  displayName: 'Parse AKS Cluster Resource ID'
```

- **Explanation:**
  - The `cut` command is used to extract the necessary parts of the `aksclusterresourceid` string.
  - The `task.setvariable` command sets the extracted values as pipeline variables (`sub`, `rg`, and `clustername`) that you can use in subsequent steps.
  - This method eliminates the need for the `.env` file by deriving variables from the resource ID provided directly in the pipeline.

#### 3. **Using Extracted Variables in Other Pipeline Jobs**
Once you’ve set these variables, you can access them in subsequent jobs or steps of the pipeline.

For example, in Azure Pipelines, you can reference the variables like this:

```yaml
- script: |
    echo "Subscription: $(sub)"
    echo "Resource Group: $(rg)"
    echo "Cluster Name: $(clustername)"
  displayName: 'Use extracted variables'
```

#### 4. **Remove `.env` File Dependency**
You will now rely on the parsed `aksclusterresourceid` for your variables instead of sourcing them from the `.env` file. Ensure that all jobs or steps that previously referenced the `.env` file are updated to use the pipeline variables (`sub`, `rg`, and `clustername`) instead.

### Summary of Key Changes:
1. **Stop loading `.env` file**: Remove any references to the `.env` file in your pipeline configuration.
2. **Use `aksclusterresourceid` as input**: Pass this directly into the pipeline.
3. **Parse and set variables**: Use script commands to parse and export `sub`, `rg`, and `clustername` from the `aksclusterresourceid` string.
4. **Reference variables**: Update all steps and jobs to reference the new pipeline variables instead of environment variables from the `.env` file.

This approach ensures the pipeline remains self-contained and removes the dependency on external files for configuration.


---
```
#!/bin/bash

# Function to parse aksclusterresourceid
parse_aksclusterresourceid() {
    local aksclusterresourceid="$1"
    sub=$(echo "$aksclusterresourceid" | awk -F'/' '{print $3}')
    rg=$(echo "$aksclusterresourceid" | awk -F'/' '{print $5}')
    clustername=$(echo "$aksclusterresourceid" | awk -F'/' '{print $9}')
}
```
# Parse the aksclusterresourceid

```
parse_aksclusterresourceid "$aksclusterresourceid"

variables=$(cat <<EOF
  {
    "subscriptionID": "$sub",
    "resourceGroupName": "$rg",
    "action": "add",
    "aksname": "$clustername",
    "namespacename": "",
    "suffix": "test-rbactest"
  }
EOF
)

body=$(cat <<EOF
  {
    "resources": {
      "repositories": {
        "self": {
          "refName": "master"
        }
      }
    },
    "templateParameters": $variables,
    "variables": {}
  }
EOF
)

url='https://cirruspl-rbacv4functionapp.azurewebsites.net/api/aksnamespaceroleassign'
token=$(az account get-access-token --resource "-1321-427f-aa17-" | jq -r '.accessToken')

response=$(curl -L -X POST -d "$body" -H "Content-Type: application/json" -H "Authorization: Bearer $token" "$url")
echo "$response"

# Extract the status code from the response
statusCode=$(echo "$response" | tail -n1)

# Print the status code
echo "$statusCode"

# If the status code is 200, print a success message and the response
if [ "$statusCode" -eq 200 ]; then
    echo "API call successful"
    echo "$response"
else
    echo "$response"
fi

```
```
#!/bin/bash

# Example aksclusterresourceid
aksclusterresourceid="subscription/12345678/resourceGroups/rgname/providers/Microsoft.ContainerService/managedClusters/clustername"

# Extract the variables from aksclusterresourceid
sub=$(echo "$aksclusterresourceid" | cut -d'/' -f2)
rg=$(echo "$aksclusterresourceid" | cut -d'/' -f4)
clustername=$(echo "$aksclusterresourceid" | cut -d'/' -f8)

# Export the variables
export sub
export rg
export clustername

# Print the variables to verify
echo "Subscription: $sub"
echo "Resource Group: $rg"
echo "Cluster Name: $clustername"