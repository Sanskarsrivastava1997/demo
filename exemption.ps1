

$rgName = "rg-shared-01"
$subscriptionName = "Pay-As-You-Go"
$policyAssignmentName = "dd51899476494c76b052c8f6"
$policyExemptionName = -join ($subscriptionName, "-", "$rgName","_05")
$resourceId = "/subscriptions/ee38476f-d7da-4b05-86b3-6904bdf3bb57/resourceGroups/rg-shared-01"
$metadata = '{"correlationId": "1234"}' | ConvertFrom-Json
$policySetDefinitionNameInput = @()



$policyAssignmentId = (az policy assignment show --name $policyAssignmentName | ConvertFrom-Json).id

$policyDefinitionType = ((az policy assignment show --name $policyAssignmentName | ConvertFrom-Json).policyDefinitionId -split '/')

$definitionName = ((az policy assignment show --name $policyAssignmentName | ConvertFrom-Json).policyDefinitionId -split '/')[-1]

if ($policyDefinitionType -contains "policySetDefinitions") {

    $policySetDefinitionIds = (az policy set-definition show --name $definitionName | ConvertFrom-Json).policyDefinitions.policyDefinitionId
    echo "checking definition Ids..."
    $definitionIdFlag = "true"
    $definitionIds = @()
    foreach ($policyName in $policySetDefinitionNameInput) {
        $definitionId = (az policy definition show --name $policyName | ConvertFrom-Json).id
        $definitionIds += $definitionId
        if ($policySetDefinitionIds -contains "$definitionId") {
            Write-Output "$definitionId is in policy Set Definition."
        }
        else {
            Write-Output "$definitionId is not in policy Set Definition."
            $definitionIdFlag = "false"
        }
    }
    if ($definitionIdFlag -eq "false") {
       Write-Output "Please validate the policy set definitions name"
    }
    else{
        echo $definitionIds
        $definitionReferenceIds = ((az policy set-definition show --name $definitionName | ConvertFrom-Json).policyDefinitions | Where-Object {$_.policyDefinitionId -In $definitionIds}).policyDefinitionReferenceId
        echo $definitionReferenceIds
        if($definitionReferenceIds.Length -ne 0){
            az policy exemption create --name $policyExemptionName --description "Temporary exemption for IAC deployments" --metadata $metadata --display-name $policyExemptionName  --exemption-category Waiver --policy-assignment $policyAssignmentId --scope $resourceId --policy-definition-reference-ids $definitionReferenceIds
        }
        else{
            az policy exemption create --name $policyExemptionName --description "Temporary exemption for IAC deployments" --metadata $metadata --display-name $policyExemptionName  --exemption-category Waiver --policy-assignment $policyAssignmentId --scope $resourceId
        }
    }
    
}
else {
    $policyDefinitionId = (az policy definition show --name $definitionName | ConvertFrom-Json).id
    az policy exemption create --name $policyExemptionName --description "Temporary exemption for IAC deployments" --metadata $metadata --display-name $policyExemptionName  --exemption-category Waiver --policy-assignment $policyAssignmentId --scope $resourceId 
}


