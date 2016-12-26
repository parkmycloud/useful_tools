#!/bin/bash

while [ -z $AppName  ]; 
do
    read -p "What do you want to call it? (e.g., ParkMyCloud Azure Dev): " AppName
done


openssl req -x509 -days 3650 -newkey rsa:2048 -out cert.pem -nodes -subj "/CN=$AppName" >>  /dev/null 2>&1
cat ./privkey.pem cert.pem > $AppName.pem
rm -f ./privkey.pem cert.pem

AzureCert=` awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' $AppName.pem | grep -v BEGIN | grep -v END` 


# AzureCert=`sed -n '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' ./$AppName.pem`
# sed -n '/-----BEGIN CERTIFICATE----- /,/ -----END CERTIFICATE-----/p' ./$AppName.pem

echo $AzureCert
