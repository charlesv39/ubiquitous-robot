param(
    [string]$purviewName,
    [string]$location,
    [string]$objectId,
    [string]$resourceGroupName,
    [string]$storageAccountName,
    [string]$subscriptionId
    
)

Install-Module Az.Purview -Force
Import-Module Az.Purview

# Variables
$pv_endpoint = "https://${purviewName}.purview.azure.com"

<# function invokeWeb([string]$uri, [string]$access_token, [string]$method, [string]$body) { 
    $retryCount = 0
    $response = $null
    while (($null -eq $response) -and ($retryCount -lt 3)) {
        try {
            $response = Invoke-WebRequest -Uri $uri -Headers @{Authorization="Bearer $access_token"} -ContentType "application/json" -Method $method -Body $body
        }
        catch {
            Write-Host "[Error]"
            Write-Host "Token: ${access_token}"
            Write-Host "URI: ${uri}"
            Write-Host "Method: ${method}"
            Write-Host "Body: ${body}"
            Write-Host "Response:" $_.Exception.Response
            Write-Host "Exception:" $_.Exception
            $retryCount += 1
            $response = $null
            Start-Sleep 3
        }
    }
    Return $response.Content | ConvertFrom-Json -Depth 10
} #>

# [GET] Metadata Policy
<# function getMetadataPolicy([string]$access_token, [string]$collectionName) {
    $uri = "${pv_endpoint}/policystore/collections/${collectionName}/metadataPolicy?api-version=2021-07-01"
    $response = invokeWeb $uri $access_token "GET" $null
    Return $response
} #>

# Modify Metadata Policy
<# function addRoleAssignment([object]$policy, [string]$principalId, [string]$roleName) {
    Foreach ($attributeRule in $policy.properties.attributeRules) {
        if (($attributeRule.name).StartsWith("purviewmetadatarole_builtin_${roleName}:")) {
            Foreach ($conditionArray in $attributeRule.dnfCondition) {
                Foreach($condition in $conditionArray) {
                    if ($condition.attributeName -eq "principal.microsoft.id") {
                        $condition.attributeValueIncludedIn += $principalId
                    }
                 }
            }
        }
    }
}
 #>
# [PUT] Metadata Policy
<# function putMetadataPolicy([string]$access_token, [string]$metadataPolicyId, [object]$payload) {
    $uri = "${pv_endpoint}/policystore/metadataPolicies/${metadataPolicyId}?api-version=2021-07-01"
    $body = ($payload | ConvertTo-Json -Depth 10)
    $response = invokeWeb $uri $access_token "PUT" $body
    Return $response

} #>

# Add UAMI to Root Collection Admin
Add-AzPurviewAccountRootCollectionAdmin -AccountName $accountName -ResourceGroupName $resourceGroupName -ObjectId $objectId

# Get Access Token
<# $response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fpurview.azure.net%2F' -Headers @{Metadata="true"}
$content = $response.Content | ConvertFrom-Json
$access_token = $content.access_token #>

# 1. Update Root Collection Policy (Add Current User to Built-In Purview Roles)
<# $rootCollectionPolicy = getMetadataPolicy $access_token $accountName
addRoleAssignment $rootCollectionPolicy $objectId "data-curator"
addRoleAssignment $rootCollectionPolicy $objectId "data-source-administrator"
addRoleAssignment $rootCollectionPolicy $adfPrincipalId "data-curator"
$updatedPolicy = putMetadataPolicy $access_token $rootCollectionPolicy.id $rootCollectionPolicy
 #>
# 2. Refresh Access Token
<# $response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fpurview.azure.net%2F' -Headers @{Metadata="true"}
$content = $response.Content | ConvertFrom-Json
$access_token = $content.access_token #>

