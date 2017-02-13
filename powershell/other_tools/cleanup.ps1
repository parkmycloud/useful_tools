#
# cleanup.ps1
#
# Tested with Windows 10 and Powershell 3.0
# 
# Removes Azure application, service principal, role and role map based on information in 
# ~\.PMCAzure directory (greated by get_azure_cred.ps1 script)


# Assumes you are logged in.
# 
Login-AzureRmAccount

# Pull info from ~\.PMCAzure
$PMCAzure="$HOME\.PMCAzure"

$AzureAccountLog="$PMCAzure/PMCAzureAccountLog"
$AzureAppLog="$PMCAzure/PMCAzureAppLog"
$AzureServicePrincipalLog="$PMCAzure/PMCAzureServicePrincipalLog"
$AzureRoleLog="$PMCAzure/PMCAzureRoleLog"

# Get SubscriptionID and TenantID
Get-Content $AzureAccountLog | ForEach-Object {
    $Left = $_.Split(':')[0]
    $Right = $_.Split(':')[1]

    if ($Left -match "SubscriptionID"){
        $SubscriptionID=$Right.Trim()
    }

    if ($Left -match "TenantID"){
        $TenantID = $Right.Trim()
    }
}

# Get App DisplayName
Get-Content $AzureAppLog | ForEach-Object {
    $Left = $_.Split(':')[0]
    $Right = $_.Split(':')[1]

    if ($Left -match "DisplayName"){
        $AppName = $Right.Trim()
    }
}

# Get App ObjectId
Get-Content $AzureAppLog | ForEach-Object {
    $Left = $_.Split(':')[0]
    $Right = $_.Split(':')[1]

    if ($Left -match "ObjectId"){
        $AppObjID = $Right.Trim()
    }
}

# Get ServicePrincipalID
Get-Content $AzureServicePrincipalLog | ForEach-Object {
    if ( $_ -match "$AppName" ) {
        $A = $_.Replace("$AppName","").Trim(" ") -split '\s+'
        $ServicePrincipalID = $A[1].Trim(" ")
    }
}

# Get RoleID
Get-Content $AzureRoleLog | ForEach-Object {
    $Left = $_.Split(':')[0]
    $Right = $_.Split(':')[1]

    if ($Left -match "Id"){
        $RoleID = $Right.Trim()
    }
}

# Set proper subscription
Get-AzureRmSubscription -SubscriptionId $SubscriptionID


# Remove role assignment
Remove-AzureRmRoleAssignment -ObjectId $ServicePrincipalID -RoleDefinitionId $RoleID

# Remove role
Remove-AzureRmRoleDefinition -Id $RoleID

# Remove service principal
Remove-AzureRmADServicePrincipal -ObjectId $ServicePrincipalID

# Remove application
Remove-AzureRmADApplication -ObjectId $AppObjID

# delete ~\.PMCAzure\*
del $PMCAzure\*
del $PMCAzure

