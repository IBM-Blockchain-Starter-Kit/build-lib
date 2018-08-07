#!/usr/bin/env bash

echo "######## Build chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x

echo "######## Download dependencies ########"

install_node "$NODE_VERSION" "$NVM_VERSION"

npm install

echo "######## Building chaincode ########"

npm run build
