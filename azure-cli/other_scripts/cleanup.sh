#!/bin/bash

AZUREDIR=$HOME/.Azure

AzureAppLog=$AZUREDIR/PMCAzureAppLog
AzureServicePrincipalLog=$AZUREDIR/PMCAzureServicePrincipalLog
AzureRoleLog=$AZUREDIR/PMCAzureRoleLog


AppObjID=`grep ObjectId $AzureAppLog | awk -F": " '{print $3}' | xargs`
ServicePrincipalID=`grep Id $AzureServicePrincipalLog | awk -F": " '{print $3}' | xargs`
RoleID=`grep Id $AzureRoleLog | awk -F": " '{print $3}' | xargs`

azure role assignment delete --objectId $ServicePrincipalID --roleId $RoleID
azure role delete $RoleID
azure ad sp delete $ServicePrincipalID
azure ad app delete $AppObjID

 rm -rf $AZUREDIR
