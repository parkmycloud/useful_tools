#!/bin/bash
# This script will create a defined number of test instances in Azure

# UPDATE THESE VARIABLES FOR YOUR ENVIRONMENT

# These should be obvious...
SUBSCRIPTION="your subscription number"
REGION="eastus2"

# Instance type to create.
TYPE="Standard_B1ls"

# This is a resource group to use for test
RESOURCE_GROUP="TestGoLangSDKPageHandling"

# This is the name that will be used as the base for all the VMs
BASE_VM_NAME="VM"
# Number of VMs to create - one is really enough to demonstrate the GoLang filter issue
VM_CREATE_COUNT=5

# This is the name that will be used as the base for all the Snapshots
BASE_SNAPSHOT_NAME="Snapshot"
# A VM that already exists in my RG
SNAPSHOT_SOURCE_VM="VM-0"
# Number of snapshots to create
SNAPSHOT_CREATE_COUNT=3100

function fail_on_error() {
    if [[ $? != 0 ]]; then
        if (( $# != 1 )); then
            printf "%s\n" "error: Command failed"
        else
            printf "%s\n" "error: $1"
        fi

        exit 1
    fi
}

function create_rg() {
    echo "Creating resource group $RESOURCE_GROUP in subscription $SUBSCRIPTION"
    
    az group create --name $RESOURCE_GROUP \
        --location $REGION \
        --subscription $SUBSCRIPTION
    fail_on_error "Failed to create rg: $RESOURCE_GROUP"
}

function delete_rg() {
    echo "Deleting resource group $RESOURCE_GROUP in subscription $SUBSCRIPTION"
    
    az group create --name $RESOURCE_GROUP \
        --subscription $SUBSCRIPTION
    fail_on_error "Failed to create rg: $RESOURCE_GROUP"
}

function create_snapshots() {
    echo "Creating $SNAPSHOT_CREATE_COUNT snapshots in resource group $RESOURCE_GROUP in subscription $SUBSCRIPTION"
    echo " Using the osDisk image from ${VM_NAMES[0]}.  This can take a while, so be patient...maybe go get lunch..."
    echo " Also - note that we are creating the snapshots with parm 'no-wait' - this means they will not show up"
    echo " in the Azure console until they are done, but they will still show up for the List command, and for"
    echo " the cli command: az snapshot list. Try using :"
    echo "     az snapshot list --resource-group $RESOURCE_GROUP --query '[].id' | wc -l"
    echo " to get a count of the done and pending snapshots (subtract 2 for the { and } )."
    osDiskId=$(az vm show \
        -g $RESOURCE_GROUP \
        -n ${VM_NAMES[0]} \
        --query "storageProfile.osDisk.managedDisk.id" \
        -o tsv)

    # Create a boatload of snapshots - lets not mess around
    for ((s = 0; s < $SNAPSHOT_CREATE_COUNT; s++)) ; do
        SNAPSHOT_NAME=$BASE_SNAPSHOT_NAME-$s
        echo " Creating $SNAPSHOT_NAME"

        RESULT=$(az snapshot create --name $SNAPSHOT_NAME \
            --resource-group $RESOURCE_GROUP \
            --location $REGION \
            --no-wait \
            --incremental true \
            --source $osDiskId)
        fail_on_error "Failed to create snapshot: $SNAPSHOT_NAME"
    done
}

function delete_snapshots() {
    echo "Deleting $SNAPSHOT_CREATE_COUNT snapshots in resource group $RESOURCE_GROUP in subscription $SUBSCRIPTION"
    echo " This can take a while, so be patient. (It would be faster to kill the program and then restart and delete the entire resource group...)"
    SNAPSHOTS=$(`az snapshot list --resource-group $RESOURCE_GROUP | jq -r '.[].id|join(" ")'`)
    RESULT=$(az snapshot delete --resource-group $RESOURCE_GROUP \
        --ids $SNAPSHOTS)
    fail_on_error "Failed to delete snapshots"
}

function create_instances() {
    echo "Creating $VM_CREATE_COUNT virtual machines in resource group $RESOURCE_GROUP in subscription $SUBSCRIPTION"
    for ((i = 0; i < $VM_CREATE_COUNT; i++)) ; do
        echo " Creating ${VM_NAMES[$i]}"
        # Use --no-wait so we can just issue all the commands and come back and get status after they are 
        # all requested. Much faster this way.
        az vm create --name ${VM_NAMES[$i]} \
            --resource-group $RESOURCE_GROUP \
            --size $TYPE \
            --location $REGION \
            --image UbuntuLTS \
            --public-ip-address '' \
            --nsg '' \
            --generate-ssh-keys \
            --no-wait
        fail_on_error "Failed to create VM: ${VM_NAMES[$i]}"

        VM_STATUSES[$i]="Creating"
    done

    NUM_REMAINING=${#VM_NAMES[@]}
    echo "Commanded creation of $NUM_REMAINING VMs"
    echo "Checking creation status:"

    # Loop thru all created instances until they have all built successfully
    while [ $NUM_REMAINING -gt 0 ]; do
        for ((i = 0; i < $VM_CREATE_COUNT; i++)) ; do
            # don't bother checking it again if we already know it is done
            if [[ ${VM_STATUSES[$i]} == "Succeeded" ]]; then
                continue
            fi

            VM_STATUSES[$i]=`az vm show --name ${VM_NAMES[$i]} --resource-group $RESOURCE_GROUP | jq -r '.provisioningState'`
            
            if [[ ${VM_STATUSES[$i]} == "Succeeded" ]]; then
                NUM_REMAINING=$(expr $NUM_REMAINING - 1)
                echo "VM: ${VM_NAMES[$i]} ${VM_STATUSES[$i]} ($NUM_REMAINING to go)"
            fi
        done
    done

    echo
    echo "All ${#VM_NAMES[@]} VMs created"
    echo
}

function update_instances {
    uiCOMMAND=$1
    uiCOMMAND_LABEL=$2
    for ((i = 0; i < $VM_CREATE_COUNT; i++)) ; do
        NAME=${VM_NAMES[$i]}
        echo -n "$uiCOMMAND_LABEL: $NAME"
        RESULT=$(az vm $uiCOMMAND --name $NAME --resource-group $RESOURCE_GROUP)
        # special stuff for the status command
        if [[ $uiCOMMAND_LABEL == "Status" ]]; then
            POWER=$(echo "$RESULT" | jq .powerState)
            PROV=$(echo "$RESULT" | jq .provisioningState)
            echo -n "  Power state: $POWER  Provisioning state: $PROV"
        fi
        echo
    done
}

# Initialize arrays used by the system
declare -a VM_NAMES=()
declare -a VM_STATUSES=()

# Populate the arrays with default values so we can restart this script and pick any option
for ((i = 0; i < $VM_CREATE_COUNT; i++)) ; do
    VM_NAME=$BASE_VM_NAME.$i
    VM_NAMES+=( $VM_NAME )

    VM_STATUSES+=( "Unknown" )
done

echo

echo "Login to the Azure account you want to use for access to subscription $SUBSCRIPTION"
az login
az account show -s $SUBSCRIPTION

while true; do
    # Wait for keypress
    echo "What do you want to do now?"
    echo " G - Create resource group $RESOURCE_GROUP"
    echo " N - Delete resource group $RESOURCE_GROUP (This is the fastest way to get rid of everything)"
    echo
    echo " C - Create $VM_CREATE_COUNT virtual machine instances (if they exist they will not be re-created)"
    echo " T - Terminate/delete all VMs created above (Stops all costs - can take a few minutes)"
    echo " S - Stop/deallocate all VMs (You will not be charged hourly for a stopped VM...just for the associated storage)"
    echo " R - Run all VMs (Start them up - you will start incurring hourly charges)"
    echo " L - List all VM statuses"
    echo
    echo " P - Create $SNAPSHOT_CREATE_COUNT snapshots (You need to have created the instances first)"
    echo " X - Delete these $SNAPSHOT_CREATE_COUNT snapshots (Takes a long time - faster to delete the resource group)"
    echo
    echo " Q - Quit this script with no further action"
    read -p "Choose: "
    CHOICE=$REPLY
    # echo -n $CHOICE
    echo

    case $CHOICE in
    "G" | "g")
        create_rg
        ;;

    "N" | "n")
        # nuke *everything* from orbit
        delete_rg
        ;;

    "C" | "c")
        create_instances
        ;;

    "T" | "t")
        # Terminate instances forever
        CMD="delete --yes --no-wait"
        CMD_LABEL="Terminating"
        update_instances "$CMD" "$CMD_LABEL"
        ;;

    "S" | "s")
        # Just stop instances
        CMD="deallocate --no-wait"
        CMD_LABEL="Stopping"
        update_instances "$CMD" "$CMD_LABEL"
        ;;
        
    "R" | "r")
        # Run/start instances
        CMD="start --no-wait"
        CMD_LABEL="Running"
        update_instances "$CMD" "$CMD_LABEL"
        ;;
        
    "L" | "l")
        # List the instance status
        CMD="show --show-details"
        CMD_LABEL="Status"
        update_instances "$CMD" "$CMD_LABEL"
        ;;
        
    "P" | "p")
        create_snapshots
        ;;
        
    "X" | "x")
        delete_snapshots
        ;;
        
    "Q" | "q")
        exit 0
        ;;
        
    esac
    continue
done
