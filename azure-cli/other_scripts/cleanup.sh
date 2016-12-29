#!/bin/bash

PMCAzure=$HOME/.PMCAzure

# Use separate log file for each important step.

AzureAccountLog=$PMCAzure/PMCAzureAccountLog
AzureAppLog=$PMCAzure/PMCAzureAppLog
AzureServicePrincipalLog=$PMCAzure/PMCAzureServicePrincipalLog
AzureRoleLog=$PMCAzure/PMCAzureRoleLog

# Get subscription and tenant ID's
SubscriptionID=`grep "ID" $AzureAccountLog | grep -v Tenant | awk -F": " '{print $3}' | xargs`
TenantID=`grep "Tenant ID" $AzureAccountLog | awk -F": " '{print $3}' | xargs`

AppObjID=`grep ObjectId $AzureAppLog | awk -F": " '{print $3}' | xargs`
ServicePrincipalID=`grep Id $AzureServicePrincipalLog | awk -F": " '{print $3}' | xargs`
RoleID=`grep Id $AzureRoleLog | awk -F": " '{print $3}' | xargs`

azure role assignment delete --objectId $ServicePrincipalID --roleId $RoleID --subscription $SubscriptionID
azure role delete $RoleID --subscription $SubscriptionID
azure ad sp delete $ServicePrincipalID
azure ad app delete $AppObjID

#rm -rf $PMCAzure
