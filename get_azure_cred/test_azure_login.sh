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

AzureCliInstallLog=~/.Azure/AzureCliInstall.log
AzureAccountLog=~/.Azure/PMCAzureAccount.log
AzureAppLog=~/.Azure/PMCAzureApp.log
AzureServicePrincipalLog=~/.Azure/PMCAzureServicePrincipal.log
AzureRoleLog=~/.Azure/PMCAzureRole.log
AzureRoleMapLog=~/.Azure/PMCAzureRoleMap.log

AzureRolePermsFile=~/.Azure/PMCExampleAzureRole.json

# Install nodejs and npm if they aren't installed

NodeStatus=`node -v 2>&1`

if [[ $NodeStatus =~ .*command* ]]; then
    echo "Installing nodejs and npm"
    curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash - >> $AzureCliInstallLog 2>&1
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

azure login -u $Username
echo

# Get subscription and tenant ID's
azure account show > $AzureAccountLog

SubscriptionID=`grep "ID" $AzureAccountLog | grep -v Tenant | awk -F: '{print $3}'`
TenantID=`grep "Tenant ID" $AzureAccountLog | awk -F: '{print $3}'`

# Print out final values for user for ParkMyCloud cred
#   Subscription ID
#   Tenant ID

echo "Your subscription ID is $SubscriptionID."
echo
echo "Your Tenant ID is $TenantID."
echo 
echo "Enter these on the Azure credential page in ParkMyCloud."
echo 
