#!/bin/bash
#   Ubuntu 14.04.5 LTS
#   Ubuntu 16.04 LTS

# Called by get_azure_cred.sh
# Use separate log file for each important step.

AzureAccountLog=$HOME/.Azure/PMCAzureAccountLog
AzureServicePrincipalLog=$HOME/.Azure/PMCAzureServicePrincipalLog
AzureRoleLog=$HOME/.Azure/PMCAzureRoleLog
AzureRoleMapLog=$HOME/.Azure/PMCAzureRoleMapLog

SubscriptionID=`grep "ID" $AzureAccountLog | grep -v Tenant | awk -F": " '{print $3}' | xargs`
ServicePrincipalID=`grep Id $AzureServicePrincipalLog | awk -F": " '{print $3}' | xargs`
RoleID=`grep Id $AzureRoleLog | awk -F": " '{print $3}' | xargs`

# Assign role to application service principal
azure role assignment create --objectId "$ServicePrincipalID" --roleId "$RoleID"  --scope "/subscriptions/$SubscriptionID" > $AzureRoleMapLog
# azure role assignment create --objectId $ServicePrincipalID  --roleId $RoleID  --scope "/subscriptions/$SubscriptionID" > $AzureRoleMapLog

echo "Role has been mapped to service principal for application."
echo 

