#!/bin/bash
# This script has been tested in 
#   Ubuntu 14.04.5 LTS
#   Ubuntu 16.04 LTS
#
# To properly execute this script the Azure user must have permissions in AD
# - Create an app
# - Create a service principal
# - Create a role
# - Map role to service princpal
#
# Reference: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal-cli

PMCAzure=$HOME/.PMCAzure
AzureCliInstallLog=$PMCAzure/0.AzureCliInstallLog
AzureLoginLog=$PMCAzure/1.PMCAzureLoginLog
AzureAccountLog=$PMCAzure/2.PMCAzureAccountLog
AzureAccountDetailsLog=$PMCAzure/3.PMCAzureAccountDetailsLog
AzureTenantLoginLog=$PMCAzure/4.PMCAzureTenantLoginLog
AzureAppLog=$PMCAzure/5.PMCAzureAppLog
AzureServicePrincipalLog=$PMCAzure/6.PMCAzureServicePrincipalLog
AzureRoleLog=$PMCAzure/7.PMCAzureRoleLog
AzureRoleMapLog=$PMCAzure/8.PMCAzureRoleMapLog

AzureRolePermsFile=$PMCAzure/PMCExampleAzureRole.json
UserName=testuser@parkmycloud.com


# check for whiptail
haswhip=`which whiptail`
# if it is not installed, fall back on dialog
if [ -z "$haswhip" ]; then
	alias whiptail='dialog'
	hasdialog=`which dialog`
	if [ -z "$hasdialog" ]; then
		echo "This program requires either the whiptail or dialog programs to run."
		echo "Please install one of them and ensure the program is in your path."
		exit 1
	fi
fi

# check for jq
hasjq=`which jq`
if [ -z "$haswhip" ]; then
		echo "This program requires the jq utility to run."
		echo "Please install it and ensure the program is in your path."
		exit 1
fi

# Install Azure CLI (if it doesn't exist already)
AzureCmd="az"
hasAzureCli=`which $AzureCmd`
if [ -z "$hasAzureCli" ]; then
	echo "This program requires the Azure CLI to run"
	echo "Please install it using the documentation at the following site:"
	echo "    https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest"
	exit 1
fi

AzureVersion=`$AzureCmd --version`
AzureVersion=`echo $AzureVersion | awk '{print $2}'`
echo "You have Azure CLI version: $AzureVersion"
major=`echo $AzureVersion | cut -d. -f1`
minor=`echo $AzureVersion | cut -d. -f2`
if [[ $major < 2 || ($major == 2 && $minor < 1) ]]; then
	echo "This program requires Azure CLI version 2.1.0 or higher"
	echo "Please update the CLI using the documentation at the following site:"
	echo "    https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest"
	echo "Note that in some cases you need to uninstall the current version in order to get the"
	echo "latest version.  We have found that for Ubuntu environments, the single command method at:"
	echo "    https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest#install-with-one-command"
	echo "is more reliable for getting the latest version than apt-get upgrade."
	exit 1
fi

function fail_on_error() {
	theErr=$?
if [ $theErr != 0 ]; then
	echo
    if (( $# != 1 )); then
        printf "\n%s\n" "error $theErr: Command failed"
    else
        printf "\n%s\n" "error $theErr: $1"
    fi

	if [ "$AzureVersion" != "none" ]; then
		echo
		#$AzureCmd logout
		#echo "Logged out of Azure CLI"
	fi

    exit 1
fi
}

function whiptail_result() {
if [ $? != 0 ]; then
    if (( $# != 1 )); then
		echo
        echo "User cancelled script"
    else
		echo
        echo "Error in whiptail processing"
    fi

	if [ "$AzureVersion" != "none" ]; then
		echo
		$AzureCmd logout
		echo "Logged out of Azure CLI"
	fi

    exit 1
fi
}

# from https://gist.github.com/cjus/1047794
# Call with: jsonValue <json key to search for> [<occurrence #>]
# Where:
#    Occurrence # is a number to indicate which instance of the key to search for, 
#			if it appears multiple times in the json. If not included, function will 
#			return all values found for the key
# Ex:
#    mValue=$(cat my.json | jsonValue myKey 1)
#
#	 Searches the piped json data for the key "myKey" and outputs the value into myValue
#
function jsonValue() {
	KEY=$1
	num=$2
	awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

# Initialize Parameters
# Create hidden directory for stuff if it doesn't exist


if [ ! -d $PMCAzure ]; then
    mkdir $PMCAzure
	fail_on_error "Unable to create $PMCAzure folder - please check your permissions for the current working directory"
else
	# Clean up the temp files in case this is a repeat run
	rm $PMCAzure/*
fi


# checks the status of the login
# Call as: check_az_login <name of log file to insect>
function check_az_login() {
    az_login_status=`grep cloudName $1`
	#echo "Using cloudname $az_login_status"

    if [ -z "$az_login_status" ]; then
		#echo "Login failed for user: $Username"

		whiptail --title "Login failed - error shown below" \
			--scrolltext \
			--textbox $1
    fi
}

# Login to Azure
# Call as: az_login [<login options>]
#	Where <login options> is optional and will most likely be --tenant tenant-id
#
# Prompt for username. 
# - Can't be NULL
# - Trap failed login and prompt user to try again

# See https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail for whiptail how-to
function az_login() {

	# az_login_status is set in the check_az_login function
while [ -z "$az_login_status" ]; do

	if (whiptail --title "Browser available?" \
		--yesno "The Azure CLI uses a web browser to securely authenticate with Azure. Does this computer have a web browser? If not, we can use a different method to login." 15 70 \
		3>&1 1>&2 2>&3) then
		MFAEnabled="yes"
		whiptail --title "Using secure browser login" \
			--msgbox "We will now open a web browser window for the Azure CLI login. The script will continue when you have logged in." \
			15 70
		echo "Requesting Azure CLI login with web browser."
		$AzureCmd login $1 > $AzureLoginLog
		fail_on_error "Login failed"
	else
		whiptail --title "Using headless login" \
			--msgbox "We will now use the Azure CLI login option for headless systems. Follow the instructions on the command line that will appear in a moment. The script will continue when you have completed the login process using a browser on another computer." \
			15 70
		echo "Requesting Azure CLI login with web browser on another system."
		$AzureCmd login $1 --use-device-code > $AzureLoginLog
		fail_on_error "Login failed"
	fi

	check_az_login $AzureLoginLog
done
}

az_login

$AzureCmd account list --output json > $AzureAccountLog
fail_on_error "Unable to get account list"

# Get a list of the unique tenant IDs
UniqueTenantIDs=(`jq -r '[.[].tenantId] | unique | .[]' $AzureAccountLog`)

# debug echo "Unique tenants: ${UniqueTenantIDs[@]}"

# get the default TenantID
DefaultTenantID=(`jq -r '.[] | select(.isDefault == true) | .tenantId' $AzureAccountLog`)
# debug echo "Found default tenant: $DefaultTenantID"

# Is there more than one tenant ID?
if [ ${#UniqueTenantIDs[@]} > 1 ]; then
	# Assemble a one-dimensional array that contains a sequence of subscription, 
	# account name, off, repeated.  This is the format needed for the whiptail 
	# checklist widget.
	declare -a tenant_menu_array
	i="0"
	while [ $i -lt ${#UniqueTenantIDs[@]} ]; do
		tenant_menu_array[((i*3))]="${UniqueTenantIDs[$i]}"

		# is this the default?
		if [ "${UniqueTenantIDs[$i]}" = "$DefaultTenantID" ]; then
			tenant_menu_array[((i*3+1))]="(default)"
			tenant_menu_array[((i*3+2))]="on"
		else
			tenant_menu_array[((i*3+1))]=""
			tenant_menu_array[((i*3+2))]="off"
		fi
		i=$[$i+1]
	done

	TenantID=$(whiptail --title "Your Tenants" \
		--separate-output \
		--radiolist "Your account has access to multiple tenants - please select which one to use" \
		15 78 5 "${tenant_menu_array[@]}" \
		3>&1 1>&2 2>&3)
	whiptail_result
else
	# there is only one
	TenantID=${UniqueTenantIDs[0]}
fi



# is the user logged-in to the correct account for this tenant ID?
if [ "$TenantID" != "$DefaultTenantID" ]; then
	echo "Logging out of current Azure account, and logging back in to requested Tenant..."
	$AzureCmd logout
	# try to login with the same creds as before
	$AzureCmd login -u $Username -p $AzurePassword --tenant $TenantID > $AzureTenantLoginLog
	fail_on_error "Login failed"
	check_az_login $AzureTenantLoginLog

	# if that did not work, then ask user to login again with correct username and password
	if [ -z "$az_login_status" ]; then
		whiptail --title "New login required" \
			--msgbox "Unable to access tenant $TenantID with your current login. Please login again using an account with correct access." \
		15 78
		az_login --tenant $TenantID
	fi
fi

#debug echo "You selected tenant ID: $TenantID"

# Get the subscriptions for just the good tenant
SubscriptionIDs=(`cat $AzureAccountLog | grep $TenantID | cut -f2`)
AccountNames=(`cat $AzureAccountLog | grep $TenantID | cut -f4`)

SubscriptionIDs=(`jq -r --arg TENANTID "$TenantID" '.[] | select(.tenantId==$TENANTID) | .id'  $AzureAccountLog`)
AccountNames=(`jq -r --arg TENANTID "$TenantID" '.[] | select(.tenantId==$TENANTID) | .name'  $AzureAccountLog`)

# How many subscriptions are there?
CountSubs=${#SubscriptionIDs[@]}

# Assemble a one-dimensional array that contains a sequence of subscription, 
# account name, off, repeated.  This is the format needed for the whiptail 
# checklist widget.
declare -a menu_array
i="0"
while [ $i -lt $CountSubs ]; do
	#menu_array[((i*3))]="${SubscriptionIDs[$i]}"
	menu_array[((i*3))]="($i)"
	menu_array[((i*3+1))]="${SubscriptionIDs[$i]} ${AccountNames[$i]}"
	menu_array[((i*3+2))]="off"
	i=$[$i+1]
done

#echo Menu will be: ${menu_array[*]}

SubsForPMCList=$(whiptail --title "Your Subscriptions" \
	--separate-output \
	--default-item "${SubscriptionIDs[0]}" \
	--checklist "Select one or more of the following subscriptions to enable for ParkMyCloud access" \
	20 78 10 "${menu_array[@]}" \
	3>&1 1>&2 2>&3)
whiptail_result
# convert space-seperated list to an array
SubsForPMC=(${SubsForPMCList})

#debug echo We will attempt to use subscriptions: ${SubsForPMC[*]}

	while [ -z "$DisplayName" ]; do
		DisplayName=$(whiptail --title "ParkMyCloud Application Display Name" \
			--inputbox "Enter the Azure Console display name for the ParkMyCloud application" \
			15 70 "ParkMyCloudAzureApp" \
			3>&1 1>&2 2>&3)
		whiptail_result
	done

HomePage="https://console.parkmycloud.com"
if [ "$Username" = "" ]; then
	Username=test@parkmycloud.com
fi
CorpDomain=`cut -d "@" -f 2 <<< "$Username"`
IdentifierUris="parkmycloud-$RANDOM-$RANDOM.$CorpDomain"

CredPassword="";

    while [ -z $CredPassword ]; do
		CredPassword=$(whiptail --title "Application Access Key" \
			--passwordbox "Create a password that will be used as the Application Access Key between your Azure account and the ParkMyCloud Service" \
			15 70 "" \
			3>&1 1>&2 2>&3)
		whiptail_result

		if [[ "$CredPassword" != "${CredPassword/ /}" ]]; then
			whiptail --title "Illegal password" \
				--msgbox "That password has spaces in it - please try again without spaces." 15 70
        	CredPassword=""
    	fi

		ConfirmCredPassword=$(whiptail --title "Confirm Application Access Key" \
			--passwordbox "Confirm the application password" \
			15 70 \
			3>&1 1>&2 2>&3)
		whiptail_result

		if [ "$CredPassword" != "$ConfirmCredPassword" ]; then
			whiptail --title "Passwords do not match" \
				--msgbox "Your passwords did not match - please try again." 15 70
        	CredPassword=""
    	fi
	done

ExpirationDate=`date '+%C%y-%m-%d' -d "+1095 days"`

echo
echo "About to create application service account in Azure using:"
echo "  Display name:         $DisplayName"
echo "  Home page:            $HomePage"
echo "  Identifier URIs:      $IdentifierUris"
echo "  Password expiration:  $ExpirationDate (3 years)"
#debug echo "  Application password: $CredPassword"
#debug echo "About to run:"
#debug echo "$AzureCmd ad app create --display-name '$DisplayName' --homepage $HomePage --identifier-uris $IdentifierUris --password $CredPassword --output json"
$AzureCmd ad app create --display-name "$DisplayName" \
	--homepage $HomePage \
	--identifier-uris $IdentifierUris \
	--password $CredPassword \
	--end-date $ExpirationDate \
	--output json > $AzureAppLog

fail_on_error "Unable to create application service account. See $AzureAppLog"

AppID=(`jq -r '.appId' $AzureAppLog`)
echo "Application service account created."
echo "Received AppID: $AppID"
echo
echo -n "Creating Service Principal..."
$AzureCmd ad sp create --id $AppID --output json > $AzureServicePrincipalLog
fail_on_error "Unable to create Service Principal. See $AzureServicePrincipalLog"
ServicePrincipalObjectID=(`jq -r '.objectId' $AzureServicePrincipalLog`)
echo "Received Service Principal Object ID: $ServicePrincipalObjectID"

echo -n "Waiting for Service Principal to show up in Azure AD..."
while [ -z "$SP_Present" ];
do
	echo -n "."
	# debug echo "trying command: $AzureCmd ad sp list --all --output json | jq -r --arg SPOID $ServicePrincipalObjectID '.[] | select(.objectId==\$SPOID)'"
    SP_Present=`$AzureCmd ad sp list --all --output json | jq -r --arg SPOID $ServicePrincipalObjectID '.[] | select(.objectId==$SPOID)'`
    sleep 1
done
# debug echo $SP_Present
echo "ok"

echo
echo "Downloading ParkMyCloud Azure Policy Template"
curl https://s3.amazonaws.com/parkmycloud-public/PMCAzureRecommendedPolicy.json -o $PMCAzure/PMCAzureRecommendedPolicy.json

echo
echo "Tailoring the Template for your account..."
rm -f $PMCAzure/PolicySubs
touch $PMCAzure/PolicySubs
for sub in ${SubsForPMC[@]}; do
	echo "Adding subscription: ${SubscriptionIDs[$sub]}"
	echo "    \"/subscriptions/${SubscriptionIDs[$sub]}\"," >> $PMCAzure/PolicySubs
done

# Create a sed script to perform the substitution of the subscriptions.
# Yes, this could be done in one line, but it is ugly and painful to tweak/troubleshoot
echo "/\"\/subscriptions\/<Your_subscription_ID_here>\"/ {" > $PMCAzure/script.sed
echo " r $PMCAzure/PolicySubs" >>  $PMCAzure/script.sed
echo " d" >>  $PMCAzure/script.sed
echo "}" >>  $PMCAzure/script.sed

echo "Substituting subscriptions into policy..."
sed -f $PMCAzure/script.sed $PMCAzure/PMCAzureRecommendedPolicy.json > $PMCAzure/PMCAzurePolicyCustomized.json
fail_on_error "Failed to customize policy subscriptions. See $PMCAzure/PMCAzurePolicyCustomized.json"

# Add a datestamp to the role definition - this is done to prevent a duplicate 
# name error in case you have done this before...
DATE=`date '+%Y-%m-%d %H:%M:%S'`
sed -i "s/ParkMyCloud Limited Access/ParkMyCloud limited access policy as of $DATE/g" \
	$PMCAzure/PMCAzurePolicyCustomized.json
fail_on_error "Failed to customize policy name. See $PMCAzure/PMCAzurePolicyCustomized.json"

echo
echo "Using the following policy:"
cat $PMCAzure/PMCAzurePolicyCustomized.json
echo

echo
echo -n "Creating role definition in Azure..."
$AzureCmd role definition create --role-definition $PMCAzure/PMCAzurePolicyCustomized.json \
	--output json > $AzureRoleLog
fail_on_error "Unable to create role definition.  See $AzureRoleLog"

RoleDefinitionID=(`jq -r '.name' $AzureRoleLog`)
echo "done. Using Role definition ID: $RoleDefinitionID"

echo
echo "For each subscription, assigning custom role to service principal..."
rm -f $AzureRoleMapLog
touch $AzureRoleMapLog
for sub in ${SubsForPMC[@]}; do
	echo -n "Assigning role to subscription: ${SubscriptionIDs[$sub]}..."
	# Watch out for gotcha described here: https://docs.microsoft.com/bs-latn-ba/azure/role-based-access-control/role-assignments-template#new-service-principal
	#debug echo "Using cmd: $AzureCmd role assignment create --scope /subscriptions/${SubscriptionIDs[$sub]} --assignee-object-id $ServicePrincipalObjectID --assignee-principal-type ServicePrincipal --role \"$RoleDefinitionID\""
	echo "Assigning role to subscription: ${SubscriptionIDs[$sub]}" >> $AzureRoleMapLog
	$AzureCmd role assignment create --scope /subscriptions/${SubscriptionIDs[$sub]} \
		--assignee-object-id $ServicePrincipalObjectID \
		--assignee-principal-type ServicePrincipal \
		--role "$RoleDefinitionID" >> $AzureRoleMapLog
	fail_on_error "Unable to assign role to subscription.  See error echoed above or final entry in $AzureRoleMapLog for details. If the error says the Principal does not exist in the directory, then you may not be running the most recent Azure CLI."
	echo "ok"
done
#debug echo "See $AzureRoleMapLog"
echo 

# Print out final values for user for ParkMyCloud cred
echo "============================================================================"
echo "Credential creation complete"
echo "============================================================================"
echo
echo "Enter these values on the Azure Add Credential page in ParkMyCloud."
echo "If you have multiple subscriptions, each will require its own "
echo "ParkMyCloud credential."
echo
i=1
for sub in ${SubsForPMC[@]}; do
	echo "For credential $i, use values:"
	echo "  Cloud Credential Nickname: ${AccountNames[$sub]}"
	echo "            Subscription ID: ${SubscriptionIDs[$sub]}"
	echo "                   Offer ID: See the subscription details in Azure Console"
	echo "                             (Note: Azure Enterprise Agreement customers"
	echo "                             can leave Offer ID blank)"
	echo "                  Tenant ID: $TenantID"
	echo "                     App ID: $AppID"
	echo "             App Access Key: Password you created a moment ago"
	echo "        Password expiration: $ExpirationDate"
	echo 
	i=$[$i+1]
done
echo "The Cloud Credential Nickname can be tailored as desired, but must "
echo "be unique within your ParkMyCloud account."
echo
echo "In order for the ParkMyCloud service to provide correct pricing "
echo "information, you should provide the Azure Offer ID for your "
echo "subscription.  This can be found in the Azure Console, under Cost "
echo "Management + Billing, and then Subscriptions.  Select the Subscription "
echo "associated with the ParkMyCloud account.  Within the details screen "
echo "you will see the Offer ID field, usually as a code starting with 'MS'."
echo "If you cannot find your Offer ID, ParkMyCloud will use a default "
echo "value for now, and you can come back and add it later. Your pricing "
echo "values may be incorrect until this is done."
echo 
echo "All of the credentials listed below use the Application:"
echo "  Display name:         $DisplayName"
echo "This can be seen in the Azure console at Azure Active Directory-->App"
echo "Registrations, and select/search under the All Applications option"
echo
echo "Script log items are stored at $HOME/.PMCAzure"
echo
echo "============================================================================"

#echo "If you want to login interactively with this service principal, enter the following from the CLI:"
#echo 
#echo "azure login -u $ServicePrincipalName --service-principal --tenant $TenantID"
#echo
#echo


