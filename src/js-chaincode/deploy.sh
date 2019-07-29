#!/usr/bin/env bash

# Go chaincode specific deploy script

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain-v2.sh"

$DEBUG && set -x

if [[ ! -f $CONFIGPATH ]]; then
  echo "No deploy configuration at specified path: ${CONFIGPATH}"
  exit 1
fi

echo "######## Print Environment ########"

# /root
echo "=> HOME ${HOME}"
ls -aGln $HOME

# /home/pipeline/...
echo "=> ROOT ${ROOTDIR}"
ls -aGln $ROOTDIR

setup_env

build_fabric_cli $FABRIC_CLI_DIR
install_jq

# if [[ ! -n $(command -v fabric-cli) ]]; then
#   exit_error "fabric-cli interface not found in PATH env variable"
# fi
# if [[ ! -n $(command -v jq) ]]; then
#   exit_error "jq interface not found in PATH env variable"
# fi
