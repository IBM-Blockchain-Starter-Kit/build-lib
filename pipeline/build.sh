#!/bin/bash -x

ls -la
echo "######## Build chaincode ########"

mkdir build
cd build

# Download and install go binaries in current directory 
# This script also sets the GOPATH and GOROOT variables used later in this script
. ../pipeline/install-go.sh

#Download Hyperledger Fabric src in current directory 
# This script also set the FABRIC_SRC_DIR variable used later in this script
. ../pipeline/download-fabric.sh


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