#!/bin/bash

PMCAzure=$HOME/.PMCAzure

# Use separate log file for each important step.

AzureAppLog=$PMCAzure/PMCAzureAppLog
AzureServicePrincipalLog=$PMCAzure/PMCAzureServicePrincipalLog
AzureRoleLog=$PMCAzure/PMCAzureRoleLog

AppObjID=`grep ObjectId $AzureAppLog | awk -F": " '{print $3}' | xargs`
ServicePrincipalID=`grep Id $AzureServicePrincipalLog | awk -F": " '{print $3}' | xargs`
RoleID=`grep Id $AzureRoleLog | awk -F": " '{print $3}' | xargs`

azure role assignment delete --objectId $ServicePrincipalID --roleId $RoleID
azure role delete $RoleID
azure ad sp delete $ServicePrincipalID
azure ad app delete $AppObjID

rm -rf $AZUREDIR
