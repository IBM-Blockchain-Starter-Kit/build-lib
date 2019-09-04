#!/usr/bin/env bash

echo "======== Build chaincode ========"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x

echo "######## Download dependencies ########"
setup_env
nvm_install_node $NODE_VERSION
install_python $PYTHON_VERSION

echo "######## Building chaincode ########"
npm install
# transpile from typescript to javascript
npm run build
