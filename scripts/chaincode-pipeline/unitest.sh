#!/bin/bash -x
echo "######## Unitest chaincode ########"
source ./scripts/chaincode-pipeline/env.sh

#  assumption is that previous state placed fabric src in the build directory
echo "######## Testing chaincode ########"
go test -v chaincode