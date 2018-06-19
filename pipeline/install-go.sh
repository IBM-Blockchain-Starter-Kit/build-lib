#!/bin/bash -x

ls -la
echo "######## Begin install and configure Go ########"

sudo apt-get update
sudo apt-get install -y libtool

export GO_VERSION="1.9.2"

echo "######## Extracting and decompressing Go version ${GO_VERSION} ########"
pwd 
curl -O https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz
tar -xvf go${GO_VERSION}.linux-amd64.tar.gz
# set location for go executables
export GOROOT=$(pwd)/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=$(pwd)

echo "GOPATH: ${GOPATH}" 
echo "GOROOT: ${GOROOT}" 