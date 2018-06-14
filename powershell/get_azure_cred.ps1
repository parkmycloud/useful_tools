# This script has been tested in 
#   Windows 10 Powershell 3.0
#
# To properly execute this script the Azure user must have permissions in AD
# - Create an app
# - Create a service principal
# - Create a role
# - Map role to service princpal
#
# Reference: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal-cli


# Initialize Parameters
# Create hidden directory for stuff if it doesn't exist

$PMCAzure="$HOME\.PMCAzure"

if (-Not (test-path -Path $PMCAzure)) {

    mkdir $PMCAzure
}


# Use separate log file for each important step.

$AzureCliInstallLog="$PMCAzure\AzureCliInstallLog"
$AzureLoginLog="$PMCAzure\PMCAzureLoginLog"
$AzureAccountLog="$PMCAzure\PMCAzureAccountLog"
$AzureAppLog="$PMCAzure\PMCAzureAppLog"
$AzureServicePrincipalLog="$PMCAzure\PMCAzureServicePrincipalLog"
$AzureRoleLog="$PMCAzure\PMCAzureRoleLog"
$AzureRoleMapLog="$PMCAzure\PMCAzureRoleMapLog"
$AzureRolePermsFile="$PMCAzure\PMCExampleAzureRole.json"

# Install Azure Resource Manager and Azure modules if not already installed
#
# Modules Required: AzureRM and Azure
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name AzureRM -AllowClobber -Force


# Login to Azure
# Prompt for username. 
# - Can't be NULL
# - Trap failed login and prompt user to try again


while (-NOT ($LoggedIn)) {
    echo "Logging into Azure."
    echo ""

    $LoggedIn=Login-AzureRmAccount -ErrorAction:SilentlyContinue

    # Record login information
    echo $LoggedIn > $AzureLoginLog

}

# Determine which subscription
echo "Here are the subscriptions associated with your account:"
echo ""

Get-AzureRmSubscription > .\tmp.txt 

Get-Content .\tmp.txt | ForEach-Object{
    $Left = $_.Split(':')[0]
    $Right = $_.Split(':')[1]

    if ($Left -match "SubscriptionName") {
        $Right
    }
}

del .\tmp.txt
echo ""

while (-NOT ($SubName)) {
     $SubName=Read-Host "Enter the subscription name you want to use"
}
    
# Get subscription and tenant ID's
Get-AzureRmSubscription -SubscriptionName $SubName > $AzureAccountLog

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


# Prompt for App name. Can't be NULL
echo "Need to create a ParkMyCloud application in your subscription."
echo "Here's the catch: It must be unique. "
echo ""

while (-NOT ($AppName)){
	$AppName = Read-Host "What do you want to call it? (e.g., ParkMyCloud Azure Dev)"
}
    

# Prompt for application password
while (-NOT($AppPwd)){

    while (-NOT($AppPwd1)){
        $AppPwd1 = Read-Host "Enter password for your application"
    }

    while (-NOT($AppPwd2)){
        $AppPwd2 = Read-Host "Re-enter your password"
    }
    

    if ($AppPwd1 -match $AppPwd2){
        $AppPwd=$AppPwd1

    }
    else{
        echo "Your passwords do not match. Try again."
        echo ""
        AppPwd1=""
        AppPwd2=""
    }
        
}


# Create App

# If AppName is multiple words then replace whites spaces with "-"
$HTTPName = $AppName | %{$_ -replace (' '),('-')}

# Need proper enddate
$EndDate="2099-12-31 00:00:00Z"

$HomePage="https://console.parkmycloud.com"
$IdentifierUris="https://$HTTPName-not-used"

New-AzureRmADApplication -DisplayName $AppName -HomePage $HomePage -IdentifierUris $IdentifierUris -Password $AppPwd -EndDate $EndDate > $AzureAppLog


Get-Content $AzureAppLog | ForEach-Object {
    $Left = $_.Split(':')[0]
    $Right = $_.Split(':')[1]

    if ($Left -match "ApplicationId"){
        $AppID = $Right.Trim()
    }
}


# Create Service Principal for App
New-AzureRmADServicePrincipal -ApplicationId $AppID > $AzureServicePrincipalLog

echo ""
echo "Created service principal for application."
echo "" 

$ServicePrincipalName = $AppName

Get-Content $AzureServicePrincipalLog | ForEach-Object {
    if ( $_ -match "$AppName" ) {
        $A = $_.Replace("$AppName","").Trim(" ") -split '\s+'
	$ServicePrincipalID = $A[1].Trim(" ")
    }
}


# Create custom role with limited permissions
# Generate permissions file

echo "{" > $AzureRolePermsFile
echo "    ""Name"": ""$AppName""," >> $AzureRolePermsFile
echo "    ""Description"": ""$AppName Role""," >> $AzureRolePermsFile
echo "    ""IsCustom"": ""True""," >> $AzureRolePermsFile
echo "    ""Actions"": [" >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachines/read""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachines/*/read""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachines/start/action""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachines/deallocate/action""," >> $AzureRolePermsFile
echo "        ""Microsoft.Network/networkInterfaces/read""," >> $AzureRolePermsFile
echo "        ""Microsoft.Network/publicIPAddresses/read""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachineScaleSets/read""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachineScaleSets/write""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachineScaleSets/start/action""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachineScaleSets/deallocate/action""," >> $AzureRolePermsFile
echo "        ""Microsoft.Compute/virtualMachineScaleSets/*/read""," >> $AzureRolePermsFile
echo "        ""Microsoft.Resources/subscriptions/resourceGroups/read""" >> $AzureRolePermsFile
echo "    ]," >> $AzureRolePermsFile
echo "    ""NotActions"": []," >> $AzureRolePermsFile
echo "    ""AssignableScopes"": [" >> $AzureRolePermsFile
echo "    ""/subscriptions/$SubscriptionID""" >> $AzureRolePermsFile
echo "    ]" >> $AzureRolePermsFile
echo "}" >> $AzureRolePermsFile

New-AzureRmRoleDefinition -InputFile $AzureRolePermsFile > $AzureRoleLog

echo "Created limited access role for app."
echo "" 

# Get RoleID
Get-Content $AzureRoleLog | ForEach-Object {
    $Left = $_.Split(':')[0]
    $Right = $_.Split(':')[1]

    if ($Left -match "Id"){
        $RoleID = $Right.Trim()
    }
}


 
# Delay until Service Principal appears in Active Directory
while (-NOT ($SP_Present)){
    Get-AzureRmADServicePrincipal > tmp.txt 

    Get-Content .\tmp.txt | ForEach-Object {
        if ( $_ -match "$ServicePrincipalID" ) {
            $A = $_.Replace("$AppName","").Trim(" ") -split '\s+'
	    $SP_Present = $A[1]
	    echo "Service Principal $SP_Present found."
	    echo ""
        }
    }

    sleep 30 

    del .\tmp.txt
}


# Map role to service principal

New-AzureRmRoleAssignment -ObjectId $ServicePrincipalID -RoleDefinitionId $RoleID -Scope "/subscriptions/$SubscriptionID" > $AzureRoleMapLog

echo "Role has been mapped to service principal for application."
echo ""

# Print out final values for user for ParkMyCloud cred
#   Subscription ID
#   Tenant ID
#   App ID (Client ID)
#   App API Access Key

echo "Subscription ID: $SubscriptionID"
echo "      Tenant ID: $TenantID"
echo "         App ID: $AppID"
echo " API Access Key: $AppPwd"
echo ""
echo "Enter these on the Azure credential page in ParkMyCloud."
echo ""



