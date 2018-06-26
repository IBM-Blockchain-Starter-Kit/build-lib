#!/bin/bash -x
echo "######## Begin install and configure Go ########"

sudo apt-get update
sudo apt-get install -y libtool

source ./scripts/chaincode-pipeline/env.sh

echo "######## Extracting and decompressing Go version ${GO_VERSION} ########"
curl -O https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
tar -xvf go${GO_VERSION}.linux-amd64.tar.gz
# set location for go executables
# export GOROOT=$(pwd)/go
# export PATH=${GOROOT}/bin:$PATH
# export GOPATH=$(pwd)

# echo "GOPATH: ${GOPATH}" 
# echo "GOROOT: ${GOROOT}" 
