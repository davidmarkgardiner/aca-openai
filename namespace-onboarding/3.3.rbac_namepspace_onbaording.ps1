function Add-aksnamespaceRoleAssignment {

    param(

        $namespacename,

        $subscriptionID,

        $resourceGroupName,

        $aksname,

        [Parameter(Mandatory = $true)][ValidateSet("Add", "Remove")]

        [string]$action,

        $suffix

    )

    if ($suffix -like "dev*") {

        $role = "CDG"

        $env = "DEV"

    }

    elseif ($suffix -like "te1*") {

        $role = "CDM"

        $env = "TEST"

    }

    elseif ($suffix -like "uat*") {

        $role = "CDL"

        $env = "UAT"

    }

    elseif ($suffix -like "preprod*") {

        $role = "CDW"

        $env = "PREPROD"

    }

    elseif ($suffix -like "prod*") {

        $role = "CDS"

        $env = "PROD"

    }


    $groups = @("MIM_HSJ-$role`_$namespacename`_APPSUPPORT", "MIM_HSJ-$role`_$namespacename`_DEPLOYER", "MIM_HSJ-$role`_$namespacename`_DEVELOPER", "MIM_HSJ-$role`_$namespacename`_DEVOPS", "MIM_HSJ-$role`_$namespacename`_OBSERVER") 

    $readerGroup = "MIM_HSJ-$role`_$namespacename`_OBSERVER"

    $adminGroup = "MIM_HSJ-$role`_$namespacename`_APPSUPPORT"

    $deployspn = "SVC_$env`_$namespacename`_deploy"

    $roleadmin = 'customrole-namespace-admin'

    $rolereader = 'customrole-namespace-reader'

    $roleclusteruser = 'Azure Kubernetes Service Cluster User Role'

    $clusterscope = "/subscriptions/$subscriptionID/resourcegroups/$resourceGroupName/providers/Microsoft.ContainerService/managedClusters/$aksname"

    $namespacescope = "$clusterscope/namespaces/$namespacename-$suffix"

    Write-FunctionInformationLog "`n# namespace role assignment scope is $namespacescope."

    Write-FunctionInformationLog "`n# cluster role assignment scope is $clusterscope."

    $spid = (Get-AzADServicePrincipal -DisplayName $deployspn -erroraction silentlycontinue).Id

    $readergroupObjectId = (Get-AzADGroup -DisplayName $readerGroup -erroraction silentlyContinue).Id

 

    if ($action -eq 'Add') {

        try {

            if ($env -eq 'DEV' -or $env -eq 'TEST') {

                #Assigning the role for reader group

                $isAssignmentActive = get-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue

                    if (!($isAssignmentActive)) {

                        $roleassign = New-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue -ErrorVariable c

                        if($roleassign){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleclusteruser assigned on scope clusterscope for group $readergroupObjectId."

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser CANNOT be assigned on scope clusterscope for group $readergroupObjectId Errorreason $c"

                        }

                    }else {

                        Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser assignment on scope clusterscope for group $readergroupObjectId already exists."


                    }

                # Assigning cluster user role for spn

                $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue

                    if (!($isAssignmentActive)) {

                        $roleassign = New-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue -ErrorVariable d

                        if($roleassign){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleclusteruser assigned on scope clusterscope for spn $spid"

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser CANNOT be assigned on scope clusterscope for spn $spid $d"

                        

                        }

                    }else {

                        Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser assignment on scope clusterscope for spn $spid already exists"

                    }

                    # Assigning cluster admin role for spn

                    $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue

                    if (!($isAssignmentActive)) {

                        $roleassign = New-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue -ErrorVariable e

                        if($roleassign){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin assigned on scope namespacescope for spn $spid"

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin CANNOT be assigned on scope namespacescope for spn $spid $e"

                        

                        }

                    }else {

                        Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin assignment on scope namespacescope for group $spid spn already exists"

                    }   

                foreach ($groupName in $groups) {

                    $groupObjectId = (Get-AzADGroup -DisplayName $groupName -erroraction silentlyContinue).Id

                    if ($groupName -eq $readerGroup) {             

                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $rolereader -erroraction silentlycontinue

                        if (!($isAssignmentActive)) {

                            $roleassign = New-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $rolereader -erroraction silentlycontinue -ErrorVariable a

                            if($roleassign){

                                Write-FunctionInformationLog "`n#SUCCESS# Role $rolereader assigned on scope namespacescope for group $groupObjectId."

                            }else {

                              Write-FunctionInformationLog "`n#FAILURE# Role $rolereader CANNOT be assigned on scope namespacescope for group $groupObjectId Errorreason $a"

                            }

                        }else {

                            Write-FunctionInformationLog "`n#FAILURE# Role $rolereader assignment on scope namespacescope for group $groupObjectId already exits."

                        }

                    }

                    else {

                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue

                        if (!($isAssignmentActive)) {

                            $roleassign = New-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue -ErrorVariable b

                            if($roleassign){

                                Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin assigned on scope namespacescope for group $groupObjectId."

                            }else {

                              Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin CANNOT be assigned on scope namespacescope for group $groupObjectId Errorreason $b"

                            

                            }

                        }else {

                            Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin assignment on scope namespacescope for group $groupObjectId already exists"

                        }

                    }

                    # PROD

                }   

            }

            elseif ($env -eq 'UAT' -or $env -eq 'PREPROD' -or $env -eq 'PROD') {

          

                #Assigning role for reader group

              

                $isAssignmentActive = get-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue

                if (!($isAssignmentActive)) {

                    $roleassign = New-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue -ErrorVariable h

                    if($roleassign){

                        Write-FunctionInformationLog "`n#SUCCESS# Role $roleclusteruser assigned on scope clusterscope for group $readergroupObjectId"

                    }else {

                      Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser CANNOT be assigned on scope clusterscope for group $groupObjectId $h"

                    

                    }

                }else {

                    Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser assignment on scope clusterscope for group $groupObjectId already exists"

                }

                #Assigning role for spn

                $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue

                    if (!($isAssignmentActive)) {

                      

                        $roleassign = New-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue -ErrorVariable i

                        if($roleassign){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleclusteruser assigned on scope clusterscope for spn $spid"

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser CANNOT be assigned on scope clusterscope for spn $spid $i"

                        

                        }

                    }else {

                        Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser assignment  on scope clusterscope for spn $spid already exists"

                    }

                    $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue

                    if (!($isAssignmentActive)) {

                        $roleassign = New-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue -ErrorVariable j

                        if($roleassign){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin assigned on scope namespacescope for spn $spid"

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin CANNOT be assigned on scope namespacescope for spn $spid $j" 

                        }

                    }else{

                        Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin assignment on scope namespacescope for spn $spid already exists"

                    }

                foreach ($groupName in $groups) {

                    $groupObjectId = (Get-AzADGroup  -DisplayName $groupName -erroraction silentlyContinue).Id

                    if ($groupName -eq $adminGroup) {

                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue

                        if (!($isAssignmentActive)) {

                            $roleassign = New-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue -ErrorVariable f

                            if($roleassign){

                                Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin assigned on scope namespacescope for group $groupObjectId"

                            }else {

                              Write-FunctionInformationLog "``n#FAILURE# Role $roleadmin CANNOT be assigned on scope namespacescope for group $groupObjectId $f"

                            }

                        }else {

                            Write-FunctionInformationLog "``n#FAILURE# Role $roleadmin assignment on scope namespacescope for group $groupObjectId already exists"

                        }

                    }

                    else {

                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $rolereader -erroraction silentlycontinue

                        if (!($isAssignmentActive)) {

                            $roleassign = New-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $rolereader --erroraction silentlycontinue -ErrorVariable g


                            if($roleassign){

                                Write-FunctionInformationLog "`n#SUCCESS# Role $rolereader assigned on scope namespacescope for group $groupObjectId"

                            }else {

                              Write-FunctionInformationLog "`n#FAILURE# Role $rolereader CANNOT be assigned on scope namespacescope for group $groupObjectId $g"

                            

                            } 

                        }else {

                            Write-FunctionInformationLog "`n#FAILURE# Role $rolereader assignment on scope namespacescope for group $groupObjectId already exists"


                        }

                    } 

                   

                }

            }

        }

        catch {

            Write-FunctionErrorLog "#EXCEPTION#: Error received while assiging roles. Error message $($_.exception.message) # Roles could not be assigned"

            Exit-Function -tmpBody $global:body

            EXIT

        }

    }

    elseif ($action -eq 'Remove') {
        try {
            if ($env -eq 'DEV' -or $env -eq 'TEST') {
                $isAssignmentActive = get-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName "$roleclusteruser" -erroraction silentlycontinue
                    if ($isAssignmentActive) {
                        $removerole = Remove-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName $roleclusteruser
                        if($removerole){
                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleclusteruser removed on scope clusterscope for group  $readergroupObjectId"
                        }else {
                          Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser CANNOT be removed from scope clusterscope for group $readergroupObjectId"
                        }
                    }else {
                        Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser  do not exits on  scope clusterscope for group $readergroupObjectId"
                    }
                    $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName "$roleclusteruser" -erroraction silentlycontinue
                    if ($isAssignmentActive) {
                        $removerole = Remove-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName $roleclusteruser
                        if($removerole){
                            Write-FunctionInformationLog "`n#SUCCESS# Role roleclusteruser removed on scope $clusterscope for spn  $spid"
                        }else {
                          Write-FunctionInformationLog "`n#FAILURE# Role roleclusteruser CANNOT be removed from scope $clusterscope for spn $spid"
                        }
                    }else {
                        Write-FunctionInformationLog "`n#FAILURE# Role roleclusteruser do not exists on scope $clusterscope for spn $spid"
                    }
                    $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue
                    if ( $isAssignmentActive) {
                        $removerole = Remove-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin
                        if($removerole){
                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin removed on scope namespacescope for spn  $spid"
                        }else {
                          Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin CANNOT be removed from scope namespacescope for spn $spid"
                        }
                    }else{
                        Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin do not exists on  scope namespacescope for spn $spid"
                    }
                foreach ($groupName in $groups) {
                    $groupObjectId = (Get-AzADGroup  -DisplayName $groupName -erroraction silentlyContinue).Id
                    if ($groupName -eq $readerGroup) {             
                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $rolereader -erroraction silentlycontinue
                        if ($isAssignmentActive) {
                            $removerole = Remove-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $rolereader
                            if($removerole){
                                Write-FunctionInformationLog "`n#SUCCESS# Role $rolereader removed on scope namespacescope for group  $groupObjectId"
                            }else {
                              Write-FunctionInformationLog "`n#FAILURE# Role $rolereader CANNOT be removed from scope namespacescope for group $groupObjectId"
                            }
                        }else{
                            Write-FunctionInformationLog "`n#FAILURE# Role $rolereader do not exists on  scope namespacescope for group $groupObjectId"
                        }
                    }
                    else {
                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue
                        if ($isAssignmentActive) {
                            $removerole = Remove-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin
                            if($removerole){
                                Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin removed on scope namespacescope for group  $groupObjectId"
                            }else {
                              Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin CANNOT be removed from scope namespacescope for group $groupObjectId"
                            }
                        }else {
                            Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin do not exists on scope namespacescope for group $groupObjectId"
                        }
                    }
                  

                    # PROD

                }

            }

            elseif ($env -eq 'UAT' -or $env -eq 'PREPROD' -or $env -eq 'PROD') {

                $isAssignmentActive = get-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue

                    if ($isAssignmentActive) {

                        $removerole = Remove-AzRoleAssignment -ObjectId $readergroupObjectId -Scope $clusterscope -RoleDefinitionName $roleclusteruser

                        if($removerole){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleclusteruser removed on scope clusterscope for group  $readergroupObjectId"

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser CANNOT be removed from scope clusterscope for group $readergroupObjectId"

                        }

                    }else{

                        Write-FunctionInformationLog "`n#FAILURE# Role $roleclusteruser do not exits on  scope clusterscope for group $readergroupObjectId"

                    }

                    $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName $roleclusteruser -erroraction silentlycontinue

                    if ($isAssignmentActive) {

                        $removerole = Remove-AzRoleAssignment -ObjectId $spid -Scope $clusterscope -RoleDefinitionName $roleclusteruser

                        if($removerole){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleclusteruser removed on scope $clusterscope for spn  $spid"

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role roleclusteruser CANNOT be removed from scope $clusterscope for spn $spid"

                        }

                    }else {

                        Write-FunctionInformationLog "`n#FAILURE# Role roleclusteruser do not exists on  scope $clusterscope for spn $spid"

                    }

                    $isAssignmentActive = get-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue

                    if ($isAssignmentActive) {

                        $removerole = Remove-AzRoleAssignment -ObjectId $spid -Scope $namespacescope -RoleDefinitionName $roleadmin

                        if($removerole){

                            Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin removed on scope namespacescope for spn  $spid"

                        }else {

                          Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin CANNOT be removed from scope namespacescope for spn $spid"

                        }

                    }else{

                        Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin do not exists on  scope namespacescope for spn $spid"

                    }

                foreach ($groupName in $groups) {

                    $groupObjectId = (Get-AzADGroup  -DisplayName $groupName -erroraction silentlyContinue).Id

                    if ($groupName -eq "$adminGroup") {

                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin -erroraction silentlycontinue

                        if ($isAssignmentActive) {

                            $removerole = Remove-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $roleadmin

                            if($removerole){

                                Write-FunctionInformationLog "`n#SUCCESS# Role $roleadmin removed on scope namespacescope for group  $groupObjectId"

                            }else {

                              Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin CANNOT be removed from scope namespacescope for group $groupObjectId"

                            }

                        }else{

                            Write-FunctionInformationLog "`n#FAILURE# Role $roleadmin do not exists on  scope namespacescope for group $groupObjectId"

                        }

                    }

                    else {

                        $isAssignmentActive = get-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName "$rolereader" -erroraction silentlycontinue

                        if ($isAssignmentActive) {

                            $removerole = Remove-AzRoleAssignment -ObjectId $groupObjectId -Scope $namespacescope -RoleDefinitionName $rolereader

                            if($removerole){

                                Write-FunctionInformationLog "`n#SUCCESS# Role $rolereader removed on scope namespacescope for group  $groupObjectId"

                            }else {

                              Write-FunctionInformationLog "`n#FAILURE# Role $rolereader CANNOT be removed from scope  namespacescope for group $groupObjectId"

                            }

                        }else{

                            Write-FunctionInformationLog "`n#FAILURE# Role $rolereader do not exits on  namespacescope  for group $groupObjectId"

                        }

                    }

                  

                }

            }

        }

        catch {

            Write-FunctionErrorLog "#EXCEPTION#: $($_.exception.message) # Roles could not be removed from namespacename $namespacename."

            Exit-Function -tmpBody $global:body

            EXIT

        }

    }

    $bodytestcontent = $global:body | foreach { [PSCustomObject]@{'Actions' = $_ } } | convertto-html -property 'Actions' -head $style

    $emailBody = $emailBody.replace("REPLACE", $bodytestcontent)

    $emailBody = $emailBody.replace("#subscriptionId#", $subscriptionId) 

    $emailBody = $emailBody.replace("#resourceGroupName#", $resourceGroupName)

    $emailBody = $emailBody.replace("#action#", $action)

    $emailBody = $emailBody.replace("#aksname#", $aksname)

    $emailBody = $emailBody.replace("#namespacename#", $namespacename)

  

   

    Send-MailNotification -mailFrom dl-iaas-cloud-engineering@ubs.com -mailTo @.com -mailSubject "Success! - Automated Data Plane Role Assignment Request" -mailBody $emailBody -mailRelayHost 10.57.214.37 -mailRelayPort 25                 

     

       

}