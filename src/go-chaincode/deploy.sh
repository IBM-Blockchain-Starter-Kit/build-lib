#!/usr/bin/env bash

# Go chaincode specific deploy script

source "${SCRIPT_DIR}/common/env.sh"
source "${SCRIPT_DIR}/common/utils.sh"
source "${SCRIPT_DIR}/common/blockchain.sh"

if [[ ! -f $CONFIGPATH ]]; then
  echo "No deploy configuration at specified path: ${CONFIGPATH}"
  exit 1
fi

install_jq
setup_service_constants
provision_blockchain
parse_fabric_config $CONFIGPATH
