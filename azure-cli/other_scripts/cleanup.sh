#!/bin/bash
#
# cleanup.ps1
#
# Tested with Ubuntu 16.04 LTS
# 
# Removes Azure application, service principal, role and role map based on information in 
# ~/.PMCAzure directory (greated by get_azure_cred.sh script)


# Assumes you are logged into Azure
while [ -z "$status" ];
do

    echo "Logging into Azure."
    echo

    while [ -z $Username ]; 
    do
        read -p "Enter your Azure username : " Username
    done

    azure login -u $Username > ./tmp.txt
    echo 

    status=`grep OK ./tmp.txt`

    if [ -z "$status" ]; then
       Username=""
    fi
    
    rm ./tmp.txt

done


# Pull info from ~/.PMCAzure
PMCAzure=$HOME/.PMCAzure

AzureAccountLog=$PMCAzure/PMCAzureAccountLog
AzureAppLog=$PMCAzure/PMCAzureAppLog
AzureServicePrincipalLog=$PMCAzure/PMCAzureServicePrincipalLog
AzureRoleLog=$PMCAzure/PMCAzureRoleLog

# Get SubscriptionID and TenantID
SubscriptionID=`grep "ID" $AzureAccountLog | grep -v Tenant | awk -F": " '{print $3}' | xargs`
TenantID=`grep "Tenant ID" $AzureAccountLog | awk -F": " '{print $3}' | xargs`

# Get Application ObjectID
AppObjID=`grep ObjectId $AzureAppLog | awk -F": " '{print $3}' | xargs`

# Get Service Principal ID
ServicePrincipalID=`grep Id $AzureServicePrincipalLog | awk -F": " '{print $3}' | xargs`

# Get Role ID
RoleID=`grep Id $AzureRoleLog | awk -F": " '{print $3}' | xargs`

# Delete role assignment
azure role assignment delete --objectId $ServicePrincipalID --roleId $RoleID --subscription $SubscriptionID

# Delete role
azure role delete $RoleID --subscription $SubscriptionID

# Delete service principal
azure ad sp delete $ServicePrincipalID

# Delet application
azure ad app delete $AppObjID

# Cleanup ~/.PMCAzure
rm -rf $PMCAzure

