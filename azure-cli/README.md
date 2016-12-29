##get\_azure_cred.sh

####Purpose: 

Automatically create application, service principal and limited role within AD and Azure and output parameters for ParkMyCloud.


####Description:

This script will automatically perform the following actions:

* Install nodejs, npm and azure-cli (if they are not already installed)
* Log you into your Azure account
* Create an application for you in your Active Directory
* Create an associated service principal for you in your Active Directory (which can be used to login on your behalf)
* Create a limited permission role
* Map the service principal to the limited permission role
* Output the parameters you will need to enter into ParkMyCloud.

**NOTE:** _You will need to have sufficient privileges within Azure to accomplish the above tasks._


####Steps to Use:

* Create a directory to pull this repository to your Linux system (e.g., /home/ubuntu/git).
* Change to that directory:  cd ~/git
* Clone the repository: git clone https://github.com/parkmycloud/useful_tools.git
* Change to the appropriate directory: cd ~/git/useful_tools/azure-cli
* Execute the script shown:  ./get_azure_cred.sh
* Follow the directions.


####Artifacts:

    There is a hidden directory created called ~/.PMCAzure which will store information about each step of the process:

    cd ~/.PMCAzure
    
    ls -al
    
    total 32
    
    drwxrwxr-x 2 ubuntu ubuntu 4096 Dec 27 08:08 ./
    drwxr-xr-x 8 ubuntu ubuntu 4096 Dec 28 21:50 ../
    -rw-rw-r-- 1 ubuntu ubuntu  615 Dec 27 08:07 PMCAzureAccountLog
    -rw-rw-r-- 1 ubuntu ubuntu  553 Dec 27 08:07 PMCAzureAppLog
    -rw-rw-r-- 1 ubuntu ubuntu 1188 Dec 27 08:07 PMCAzureRoleLog
    -rw-rw-r-- 1 ubuntu ubuntu  792 Dec 27 08:08 PMCAzureRoleMapLog
    -rw-rw-r-- 1 ubuntu ubuntu  488 Dec 27 08:07 PMCAzureServicePrincipalLog
    -rw-rw-r-- 1 ubuntu ubuntu  887 Dec 27 08:07 PMCExampleAzureRole.json
     

####Environment

This script was built to run in Ubuntu Linux. It has been tested in Ubuntu 14.04.5 LTS and Ubuntu 16.04 LTS.


####Updates

These scripts are maintained only a best effort basis. If you wish to make changes or fix bugs, please fork the repository, make changes there and, once you have completed your testing, open up a pull request within Github.


