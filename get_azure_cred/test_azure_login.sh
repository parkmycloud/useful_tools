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

# Print out final values for user for ParkMyCloud cred
#   Subscription ID
#   Tenant ID

echo "Your subscription ID is $SubscriptionID."
echo
echo "Your Tenant ID is $TenantID."
echo 
echo "Enter these on the Azure credential page in ParkMyCloud."
echo 
