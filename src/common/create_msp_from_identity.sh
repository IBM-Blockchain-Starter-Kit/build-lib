#!/usr/bin/env bash
## Logging helpers
source <(curl -sSL https://raw.githubusercontent.com/hyperledger/fabric-samples/master/test-network/scriptUtils.sh)

# Creates a Peer MSP for cli from an IBP identity JSON

if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    fatalln "Usage: ./create_msp_from_identity.sh dirToCreateMsp base64Cert base64CA base64Key nameOfIdentity"
fi


## Check if dir exists
[[ ! -d "$1" ]] && mkdir "$1"

mkdir -p "${1}/msp/cacerts" && \
    mkdir -p "${1}/msp/keystore" && \
    mkdir -p "${1}/msp/signcerts" && \
    mkdir -p "${1}/msp/admincerts"

cert=$2
ca=$3
key=$4
name=$5

if [[ "$cert" == "null"  ]];then
    fatalln "cert from json not found"
elif [[ "$ca" == "null"  ]];then
    fatalln "ca from json not found"
elif [[ "$key" == "null" ]];then
    fatalln "key from json not found"
fi

echo "${cert}" | base64 -d > "${1}/msp/signcerts/cert.pem"
echo "${cert}" | base64 -d > "${1}/msp/admincerts/cert.pem"
echo "${ca}" | base64 -d > "${1}/msp/cacerts/${name//[[:blank:]]/}.pem"
SIGNING_ID=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in "${1}/msp/signcerts/cert.pem" | sed 's/SHA256 Fingerprint=//g' | sed 's/://g' | tr  '[:upper:]' '[:lower:]')
echo "${key}" | base64 -d > "${1}/msp/keystore/${SIGNING_ID}_sk"