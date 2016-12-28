#!/bin/bash
# This script has been tested in 
#   Ubuntu 14.04.5 LTS
#   Ubuntu 16.04 LTS
#
# Given service principal ID, it deletes the service principal and application (if latter is desired)

# Initialize Parameters
# Create hidden directory for stuff if it doesn't exist

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


while [ -z $SpId  ]; 
do
    echo
    read -p "Enter service provider ID: " SpId
done

azure ad sp delete --objectId "$SpId"

