#!/usr/bin/env bash

echo "######## Test chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
source "${SCRIPT_DIR}/common/blockchain.sh"

$DEBUG && set -x

echo "======== Download dependencies ========"
cd $CHAINCODEPATH
nvm_install_node "$NODE_VERSION"
# npm install
# npm run build

echo "======== Run cc tests ========"
npm run test