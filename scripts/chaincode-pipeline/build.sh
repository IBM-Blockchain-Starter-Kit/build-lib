#!/bin/bash -x
echo "######## Build chaincode ########"
source ./scripts/chaincode-pipeline/env.sh

echo "######## Placing source in directory expected by go build ########"
# Let's put fabric source into gopath so that go can resolve dependencies with Fabric libraries 
mkdir -p ${GOPATH}/src/github.com/hyperledger
mv ${FABRIC_SRC_DIR} ${GOPATH}/src/github.com/hyperledger/fabric

# change to the correct path name \ path should be ./chaincode/go/example ??
echo "######## Building chaincode ########"
go build -v -x chaincode