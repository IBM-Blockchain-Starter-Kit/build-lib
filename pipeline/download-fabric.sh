#!/bin/bash -x
ls -la
echo "######## Begin download Fabric ########"
export HLF_VERSION="1.0.4"

echo "######## Extracting and decompressing Fabric version ${HLF_VERSION} ########"
curl -O -L https://github.com/hyperledger/fabric/archive/v${HLF_VERSION}.tar.gz
tar -xvf v${HLF_VERSION}.tar.gz

export FABRIC_SRC_DIR=$(pwd)/fabric-${HLF_VERSION}
echo "FABRIC_SRC_DIR: ${FABRIC_SRC_DIR}"