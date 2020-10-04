#!/usr/bin/env bash
source "$(pwd)/utils.sh"
# Creates a Peer MSP for cli from an IBP identity JSON

set -o pipefail

if [[ ! -z "$1" ]];then
    echo "Usage ./create_msp.sh ADMIN_IDENTITY_NAME outputDir"
    echo "make sure identity_file.json has no space: arg1 = $1, arg2 = $2"
    exit 1
fi

## Check if dir exists
[[ ! -d "$2" ]] && mkdir "$2"

mkdir -p "${2}/msp/cacerts" && \
    mkdir -p "${2}/msp/keystore" && \
    mkdir -p "${2}/msp/signcerts" && \
    mkdir -p "${2}/msp/admincerts"

cert=$(echo "$1" | jq -r '.cert')
ca=$(echo "$1" | jq -r '.ca')
key=$(echo "$1" | jq -r '.private_key')

if [[ -z "$cert" ]];then
    fatalln "cert from json not found"
elif [[ -z "$ca" ]];then
    fatalln "ca from json not found"
elif [[ -z "$key" ]];then
    fatalln "key from json not found"
fi

echo "${cert}" | base64 -d > "${2}/msp/signcerts/cert.pem"
echo "${cert}" | base64 -d > "${2}/msp/admincerts/cert.pem"
echo "${ca}" | base64 -d > "${2}/msp/cacerts/${1##*/}.pem"
SIGNING_ID=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in "${2}/msp/signcerts/cert.pem" | sed 's/SHA256 Fingerprint=//g' | sed 's/://g' | tr  '[:upper:]' '[:lower:]')
echo "${key}" | base64 -d > "${2}/msp/keystore/${SIGNING_ID}_sk"