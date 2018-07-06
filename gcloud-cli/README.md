####Purpose: 

Automatically create limited role within GCP and output parameters for ParkMyCloud.  Full details of each step are available at https://parkmycloud.atlassian.net/wiki/spaces/PMCUG/pages/342163506/Create+Google+Cloud+Platform+GCP+Service+Account+-+Manually+Using+gcloud+CLI


####Description:

This script will automatically perform the following actions:

* Attempt to install gcloud (if it is not already installed)
* Log you into your Google Cloud account
* Ask you to select your project
* Create a Service Account
* Download the Service Account Private Key
* Create a custom Limited Access Role
* Associate the Service Account with the custom Limited Access Role
* Output the parameters you will need to enter into ParkMyCloud.

**NOTE:** _You will need to have sufficient privileges within Google to accomplish the above tasks._


####Steps to Use:

* Create a directory to pull this repository to your Linux system (e.g., /home/ubuntu/git).
* Change to that directory:  cd ~/git
* Clone the repository: git clone https://github.com/parkmycloud/useful_tools.git
* Set your branch to the latest tagged release: (e.g., git branch v1.2)
* Change to the appropriate directory: cd ~/git/useful_tools/google-cli
* Execute the script shown:  ./gcp_bash_script.sh
* Follow the directions.


####Environment

This script should work in any environment running bash, optimally with gcloud already installed.  Follow the instructions at https://cloud.google.com/sdk/ for installing gcloud ahead of time. 


####Updates

These scripts are maintained only a best effort basis. If you wish to make changes or fix bugs, please fork the repository, make changes there and, once you have completed your testing, open up a pull request within Github.


