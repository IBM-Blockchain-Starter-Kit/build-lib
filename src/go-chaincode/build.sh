#!/usr/bin/env bash

echo "######## Build chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x


echo "######## Download dependencies ########"

# shellcheck source=src/go-chaincode/download-fabric.sh
source "${SCRIPT_DIR}/go-chaincode/download-fabric.sh"

# shellcheck source=src/go-chaincode/install-go.sh
source "${SCRIPT_DIR}/go-chaincode/install-go.sh"

install_node $NODE_VERSION $NVM_VERSION


echo "######## DEBUG ########"
echo "ls -a ."


echo "######## Placing source in directory expected by go build ########"

GOSOURCE="${GOPATH}/src"

mkdir -p "${GOSOURCE}"
cp -r "${CHAINCODEPATH}" "${GOSOURCE}/chaincode"

# Let's put fabric source into gopath so that go can resolve dependencies with Fabric libraries 
mkdir -p "${GOSOURCE}/github.com/hyperledger/"
mv "${FABRIC_SRC_DIR}" "${GOSOURCE}/github.com/hyperledger/fabric"


echo "######## Print current directories ########"
ls


# change to the correct path name \ path should be ./chaincode/go/example ??
echo "######## Building chaincode ########"
go build -v -x "chaincode/..."
