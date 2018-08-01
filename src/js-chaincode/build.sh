#!/usr/bin/env bash

echo "######## Build chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"

$DEBUG && set -x

echo "######## Download dependencies ########"

# shellcheck source=src/js-chaincode/install-node.sh
source "${SCRIPT_DIR}/js-chaincode/install-node.sh"

echo "######## Placing source in directory expected by go build ########"

echo "######## Building chaincode ########"
