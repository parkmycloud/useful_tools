#!/bin/bash
#
# Installs remap-ip scripts, allowing folks with Classic AWS instances to remap their elastic IP's after the instances restart.
# 
# Supports AWS instances running Ubuntu 14.x Linux
#
# Author: Dale Wickizer, ParkMyCloud, Inc.
# Copyright 2016. All rights reserved.
#
# NOTE: You will need an IAM user credential (access and secret key). That user will need permission to associate and dissociate
# Elastic IP addresses

echo ============================== Configuring Primary Shell Script =============================
echo 

# Setup environment variables for your installation

# AWS Default Region:
REGION=us-west-2

# Enter install director (default: /opt/ec2)
EC2_BASE=/opt/ec2

# Enter private key name (default: key.pem)...don't worry we're going to create it:
KEY=key.pem

# Enter certificate name (default: certificate.pem) ... we're going to create it as well"
CERT=cerificate.pem

# Enter your IAM user public key:
ACCESS=THISISMYACCESSKEY

# Enter your IAM user secret key:
SECRET=tHisIsMyReallyReallySecretKey

# Java home directory (default: /usr):
JAVA_HOME=/usr

cp remap-ip.template remap-ip.sh

sed -i "s|<EC2_BASE>|${EC2_BASE}|" remap-ip.sh
sed -i "s/<KEY>/$KEY/" remap-ip.sh
sed -i "s/<CERT>/$CERT/" remap-ip.sh
sed -i "s/<ACCESS>/$ACCESS/" remap-ip.sh
sed -i "s|<SECRET>|${SECRET}|" remap-ip.sh
sed -i "s/<REGION>/$REGION/" remap-ip.sh
sed -i "s|<JAVA_HOME>|${JAVA_HOME}|" remap-ip.sh

echo
echo ================================== Generating Upstart File ==================================
echo

echo "description 'Elastic-IP Remapper'" > remap-ip.conf
echo >> remap-ip.conf
echo "start on runlevel [2345]" >> remap-ip.conf
echo "stop on runlevel [12345]" >> remap-ip.conf
echo >> remap-ip.conf
echo "setuid ubuntu" >> remap-ip.conf
echo "setgid ubuntu" >> remap-ip.conf
echo >> remap-ip.conf
echo "script" >>remap-ip.conf
echo "    exec sh ${EC2_BASE}/remap-ip.sh start" >> remap-ip.conf
echo "end script" >> remap-ip.conf

sudo mv remap-ip.conf /etc/init

echo
echo ================================== Building App Directory ===================================
echo 
if [ ! -d ${EC2_BASE} ]; then
   sudo mkdir ${EC2_BASE}
   sudo mkdir ${EC2_BASE}/tools
   sudo mkdir ${EC2_BASE}/certs
   sudo chown -R ${USER:-ubuntu}:${USER:-ubuntu} ${EC2_BASE}
fi

mv remap-ip.sh ${EC2_BASE}

echo
echo =========================== Generating Self=Signed X509 Certs ===============================
echo
# Refer to http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-managing-certs.html?icmpid=docs_iam_console

if [ ! -f /usr/bin/openssl ]; then
   sudo apt-get update
   sudo apt-get install -y openssl
fi

# Generate key file
sudo /usr/bin/openssl genrsa 2048 > $EC2_BASE/certs/${KEY:-key.pem}

# Generate self-signed X509 certificate
sudo /usr/bin/openssl req -new -x509 -nodes -sha512 -days 365 -key $EC2_BASE/certs/${KEY:-key.pem} -outform PEM > $EC2_BASE/certs/${CERT:-certificate.pem}

sudo chmod 550 ${EC2_BASE}/certs
sudo chmod 440 ${EC2_BASE}/certs/*
sudo chown ${USER:-ubuntu}:${USER:-ubuntu} ${EC2_BASE}/certs/*


echo
echo ================================= Installing AWS EC2 API tools ==============================
echo
# Refer to http://aws.amazon.com/developertools/351
# And to http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/set-up-ec2-cli-linux.html#setting_up_ec2_command_linux

# First, we're going to need unzip
if [ ! -f /usr/bin/unzip ]; then
   sudo apt-get -y install unzip
fi

# Fetch it
wget -q http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip&token=A80325AA4DAB186C80828ED5138633E3F49160D9

sleep 7 # This is here because unzip sometimes gets ahead of itself

# Unpack it
/usr/bin/unzip ec2-api-tools.zip

# Move it where you need it
cp -r ec2-api-tools*/* $EC2_BASE/tools

# Clean up
rm -rf ec2-api-tools*


echo
echo ===================================== Installing Java JDK ===================================
echo 
if [ ! -x $JAVA_HOME/bin/java ]; then
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update  
    sudo apt-get install -y oracle-java8-installer
    sudo apt-get install -y oracle-java8-set-default
fi


echo
echo ===================================== Installation Complete =================================
echo

# Instuct user on last steps
echo Now, it is up to you. 
echo 
echo 1. Take this certificate and copy and paste it in the console to activate it 
echo for the IAM user whose credentials you used.  
echo 
cat ${EC2_BASE}/certs/$CERT
echo
echo Refer to http://docs.aws.amazon.com/AWSEC2/latest/CommandLineReference/ec2-cli-managing-certs.html?icmpid=docs_iam_console
echo for more details.
echo
echo
echo 2. Next, you are going to need to allocate an elastic IP address for use by this instance if you have not done so.
echo 
echo 3. Lastly, you will need to add the following userData to every instance to which you want to remap IP addresses:
echo 
echo "   userData <instance_id>  elastic-ip=aaa.bbb.ccc.ddd | hostname=<myhost.mycompany.com>"
echo
echo    The instance will need to be shutdown before you add it.
echo
echo You should be all set. Just start the instance and the specified Elastic IP will be mapped to it.
echo 
