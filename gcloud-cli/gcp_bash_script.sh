#!/bin/bash

# Manual instructions available at https://parkmycloud.atlassian.net/wiki/spaces/PMCUG/pages/342163506/Create+Google+Cloud+Platform+GCP+Service+Account+-+Manually+Using+gcloud+CLI

# 1. Install the gcloud utility
GCLOUD_CMD=$(which gcloud)
YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)
if [[ ! -z $GCLOUD_CMD ]]; then
	echo "gcloud utility installed"
elif [[ ! -z $YUM_CMD ]]; then
	sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
	yum install google-cloud-sdk
elif [[ ! -z $APT_GET_CMD ]]; then
	export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
	echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
	curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
	sudo apt-get update && sudo apt-get install google-cloud-sdk
else
	echo "error can't install package $PACKAGE"
	exit 1;
fi

# 2. Login to GCP
gcloud auth login

# 3. Select a Project for the Limited Access Role
projects_list=$(gcloud projects list | awk '{print $1}')
echo $projects_list
echo "Which project would you like to use?"
read chosenproject
gcloud config set project $chosenproject

# 4. Create the Service Account
gcloud iam service-accounts create parkmycloud-limited-svc-acct --display-name "ParkMyCloud Limited Access Service Account"

# 5. Get the fully qualified name (email address) of the new Service Account
serviceaccountemail=$(gcloud iam service-accounts list --filter "parkmycloud-limited-svc-acct" | egrep -o "[^[:space:]]+@[^[:space:]]+" | tr -d "<>")

# 6. Download the Service Account Private Key file
gcloud iam service-accounts keys create ./gcp-parkmycloud-limited-svc-acct-key.json --iam-account $serviceaccountemail

# 7. Prepare the custom Limited Access Role YAML file
wget https://s3.amazonaws.com/parkmycloud-public/ParkMyCloud-GCP-LimitedAccessRole.yaml



# 8. Create the custom Limited Access Role
gcloud iam roles create PMC_Limited --project $chosenproject --file ./ParkMyCloud-GCP-LimitedAccessRole.yaml

# 9. Associate the Service Account with the custom Limited Access Role
gcloud projects add-iam-policy-binding $chosenproject --role projects/$chosenproject/roles/PMC_Limited --member serviceAccount:$serviceaccountemail

# 10. Create the ParkMyCloud GCP Credential
echo "Use this information in the ParkMyCloud UI"
echo "The key is located at ./gcp-parkmycloud-limited-svc-acct-key.json"
echo "The project you selected is $chosenproject"