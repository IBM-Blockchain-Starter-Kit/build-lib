#!/bin/bash -x
echo "######## Begin download Fabric ########"
source ./scripts/chaincode-pipeline/env.sh

echo "######## Extracting and decompressing Fabric version ${HLF_VERSION} ########"
curl -O -L https://github.com/hyperledger/fabric/archive/v${HLF_VERSION}.tar.gz
tar -xvf v${HLF_VERSION}.tar.gz