#!/usr/bin/env bash

echo "######## Build chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x


echo "######## Download dependencies ########"
setup_env
install_python $PYTHON_VERSION

echo "=> download hfl-v${HLF_VERSION} source code"
# shellcheck source=src/go-chaincode/download-fabric.sh
source "${SCRIPT_DIR}/go-chaincode/download-fabric.sh"

echo "=> install go binaries"
# shellcheck source=src/go-chaincode/install-go.sh
source "${SCRIPT_DIR}/go-chaincode/install-go.sh"

echo "=> install node v${NODE_VERSION} via nvm v${NVM_VERSION}"
nvm_install_node $NODE_VERSION


echo "######## Placing source in directory expected by go build ########"

GOSOURCE="${GOPATH}/src"

mkdir -p "${GOSOURCE}"
cp -r "${CHAINCODEPATH}" "${GOSOURCE}/chaincode"

# Let's put fabric source into gopath so that go can resolve dependencies with Fabric libraries 
mkdir -p "${GOSOURCE}/github.com/hyperledger/"
mv "${FABRIC_SRC_DIR}" "${GOSOURCE}/github.com/hyperledger/fabric"


# change to the correct path name \ path should be ./chaincode/go/example ??
echo "######## Building chaincode ########"
install_jq
for org in $(cat ${CONFIGPATH} | jq -r 'keys | .[]'); do
  for cc_path in $(cat ${CONFIGPATH} | jq -r ".${org}.chaincode | .[] | .path"); do    
    cd ${GOSOURCE}/${cc_path}
    go build -v -x $cc_path
  done
done
cd ${ROOTDIR}
# go build -v -x "chaincode/..."


echo "######## Building fabric-cli ########"
build_fabric_cli ${FABRIC_CLI_DIR}