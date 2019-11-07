#!/usr/bin/env bash

echo "######## Build chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x

echo "======== Verify Env Variables ========"
echo "CC_REPO_DIR: $CC_REPO_DIR"
ls -agln "$CC_REPO_DIR"

echo "======== Download dependencies ========"
setup_env
install_python "${PYTHON_VERSION}"
# echo "Y" | apt-get install python2.7
nvm_install_node "${NODE_VERSION}"

echo "======== Building fabric-cli tool ========"
cd "${FABRIC_CLI_DIR}" || exit 1
npm install
npm run build
# npm link

echo "======== Building chaincode ========"
cd "$CC_REPO_DIR" || exit 1
npm install
npm run build # transpile from typescript to javascript
