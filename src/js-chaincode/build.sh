#!/usr/bin/env bash

echo "======== Build chaincode ========"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x

echo "######## Download dependencies ########"
setup_env
install_python $PYTHON_VERSION
nvm_install_node ${NODE_VERSION}

echo "######## Building fabric-cli tool ########"
cd ${FABRIC_CLI_DIR}
npm install
npm run build
npm link #?

echo "######## Building chaincode ########"
cd ${CHAINCODEPATH}
npm install
npm run build # transpile from typescript to javascript
