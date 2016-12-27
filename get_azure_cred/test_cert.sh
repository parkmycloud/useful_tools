#!/bin/bash

while [ -z $AppName  ]; 
do
    read -p "What do you want to call it? (e.g., ParkMyCloud Azure Dev): " AppName
done

AzurePemFile=$HOME/.Azure/$AppName.pem

# Create App API Key

openssl req -x509 -days 3650 -newkey rsa:2048 -out cert.pem -nodes -subj "/CN=$AppName" >>  /dev/null 2>&1
cat ./privkey.pem cert.pem > $AzurePemFile
rm -f ./privkey.pem cert.pem

AzureCert=`awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' $AzurePemFile | grep -v BEGIN | grep -v END` 
ThumbPrint=`openssl x509 -in "$AzurePemFile" -fingerprint -noout | sed 's/SHA1 Fingerprint=//g'  | sed 's/://g'`

# AzureCert=`sed -n '/^-----BEGIN CERTIFICATE-----$/,/^-----END CERTIFICATE-----$/p' ./$AppName.pem`
# sed -n '/-----BEGIN CERTIFICATE----- /,/ -----END CERTIFICATE-----/p' ./$AppName.pem

echo "Cert: $AzureCert"
echo
echo "Fingerprint: $ThumbPrint"
