#!/bin/bash
# This script has been tested in 
#   Ubuntu 14.04.5 LTS
#   Ubuntu 16.04 LTS


# Initialize Parameters
# Create hidden directory for stuff if it doesn't exist

if [ ! -d ~/.Azure ]; then
    mkdir ~/.Azure
fi

# Use separate log file for each important step.

AzureCliInstallLog= "~/.Azure/AzureCliInstallLog"
AzureLoginLog= "~/.Azure/PMCAzureLoginLog"
AzureAccountLog= "~/.Azure/PMCAzureAccountLog"
AzureAppLog= "~/.Azure/PMCAzureAppLog"
AzureServicePrincipalLog= "~/.Azure/PMCAzureServicePrincipalLog"
AzureRoleLog= "~/.Azure/PMCAzureRoleLog"
AzureRoleMapLog= "~/.Azure/PMCAzureRoleMapLog"

AzureRolePermsFile= "~/.Azure/PMCExampleAzureRole.json"

# Install nodejs and npm if they aren't installedt

NodeStatus=`node -v 2>&1`

if [[ $NodeStatus =~ .*program.* ]]; then
    echo "Installing nodejs and npm"
    curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash - > $AzureCliInstallLog 2>&1
    sudo apt-get install -y nodejs >> $AzureCliInstallLog 2>&1
    echo
fi

# Install Azure CLI (if it doesn't exist already)
# Need to figure out how to determine if azure-cli is installed

AzureStatus=`azure -v 2>&1`

if [[ $AzureStatus =~ .*command.* ]]; then
    echo "Installing azure-cli"
    sudo npm install -g azure-cli >> $AzureCliInstallLog 2>&1
    echo
fi

# Login to Azure
# Prompt for username. Can't be NULL

echo "Logging into Azure."
echo

while [ -z $Username  ]; 
do
    read -p "Enter your Azure username : " Username
done

azure login -u $Username > $AzureLoginLog

# Get subscription and tenant ID's
azure account show > $AzureAccountLog

SubscriptionID=`grep "ID" $AzureAccountLog | grep -v Tenant | awk -F: '{print $3}'`
TenantID=`grep "Tenant ID" $AzureAccountLog | awk -F: '{print $3}'`

# Prompt for App name. Can't be NULL
echo "Need to create a ParkMyCloud application in your subscription."
echo "Here's the catch: It must be unique. "
echo

while [ -z $AppName  ]; 
do
    read -p "What do you want to call it? (e.g., ParkMyCloud Azure Dev): " AppName
done


# Create App API Key

AppKey= 


# Create App
# Not sure how key is generated
# Can have -p <password> and provide password, but never get the key back
# Can use --cred-value <cred-value>, but not sure what goes here? 
# What the heck does "the value of the "asymmetric" credential type. It represents the base 64 encoded certificate" mean?

azure ad app create -n $AppName -m "https://console.parkmycloud.com" -i "https://notused" --cert-value $APIKey --end-date "12/31/2299" > $AzureAppLog

AppID=`grep AppId $AzureAppLog | awk -F: '{print $3}'`


# Create Service Principal for App
azure ad sp create -a $AppID > $AzureServicePrincipalLog

echo "Created service principal for application."
echo 

ServicePrincipalID=`grep Id $AzureServicePrincipalLog | awk -F: '{print $3}'`


# Create custom role with limited permissions
# Generate permissions file

echo "{" > $AzureRolePermsFile
echo "    \"Name\": \"ParkMyCloud Limited Access\"," >> $AzureRolePermsFile
echo "    \"Description\": \"ParkMyCloud Limited Access Role\"," >> $AzureRolePermsFile
echo "    \"IsCustom\": \"True\"," >> $AzureRolePermsFile
echo "    \"Actions\": [" >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachines/read\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachines/*/read\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachines/start/action\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachines/deallocate/action\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachineScaleSets/read\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachineScaleSets/write\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachineScaleSets/start/action\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachineScaleSets/deallocate/action\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Compute/virtualMachineScaleSets/*/read\"," >> $AzureRolePermsFile
echo "        \"Microsoft.Resources/subscriptions/resourceGroups/read\"" >> $AzureRolePermsFile
echo "    ]," >> $AzureRolePermsFile
echo "    \"NotActions\": []," >> $AzureRolePermsFile
echo "    \"AssignableScopes\": [" >> $AzureRolePermsFile
echo "    \"/subscriptions/$SubscriptionID\"" >> $AzureRolePermsFile
echo "    ]" >> $AzureRolePermsFile
echo "}" >> $AzureRolePermsFile

azure role create --inputfile $AzureRolePermsFile > $AzureRoleLog

echo "Created limited access role for app."
echo 

RoleID=`grep Id $AzureRoleLog | awk -F: '{print $3}'`


# Assign role to application service principal

azure role assignment create --objectId $ServicePrincipalID  --roleID $RoleID  --scope "/subscriptions/$SubscriptionID" > $AzureRoleMapLog

echo "Role has been mapped to service principal for application."
echo 

# Print out final values for user for ParkMyCloud cred
#   Subscription ID
#   Tenant ID
#   App ID (Client ID)
#   App Access Key (Client Secret Key)

echo "Your subscription ID is $SubscriptionID."
echo
echo "Your Tenant ID is $TenantID."
echo 
echo "Your App ID is $AppID."
echo
echo "Your API Access Key is $AppKey."
echo 
echo "Enter these on the Azure credential page in ParkMyCloud."
echo 





