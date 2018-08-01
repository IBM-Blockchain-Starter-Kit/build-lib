#!/usr/bin/env bash

# Go chaincode specific deploy script

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain.sh"

$DEBUG && set -x

if [[ ! -f $CONFIGPATH ]]; then
  echo "No deploy configuration at specified path: ${CONFIGPATH}"
  exit 1
fi

install_jq
setup_service_constants
provision_blockchain
deploy_fabric_chaincode golang $CONFIGPATH
