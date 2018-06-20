#!/bin/bash -x
echo "######## Unitest chaincode ########"
ls -la
cd build
#assumption is that previous state copied go code under build directory
export GOPATH=$(pwd)
# assumption is that previous state installed go binaries in build directory 
export GOROOT=$(pwd)/go
export PATH=${GOROOT}/bin:$PATH

#  assumption is that previous state placed fabric src in the build directory
echo "######## Testing chaincode ########"
go test -v chaincode