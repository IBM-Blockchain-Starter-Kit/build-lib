#!/bin/bash -x

source env.sh

ls -la
echo "######## Build chaincode ########"

mkdir build
cd build

echo "######## Placing source in directory expected by go build ########"
mkdir ${GOPATH}/src
# Let's put fabric source into gopath so that go can resolve dependencies with Fabric libraries 
mkdir -p  ${GOPATH}/src/github.com/hyperledger
mv ${FABRIC_SRC_DIR} ${GOPATH}/src/github.com/hyperledger/fabric
# Copy chaincode into gopath 
cp -pR ../src/chaincode ${GOPATH}/src

# change to the correct path name \ path should be ./chaincode/go/example ??
echo "######## Building chaincode ########"
go build -v -x chaincode