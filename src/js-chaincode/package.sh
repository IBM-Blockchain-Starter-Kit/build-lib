#!/usr/bin/env bash

export ENABLE_PEER_CLI=true
# Common deploy script for chaincode
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain.sh"

: "${CC_REPO_DIR:?"CC_REPO_DIR not set" }"
: "${CC_NAME:?"CC_NAME not set" }"
: "${CC_VERSION:?"CC_VERSION not set" }"

packageCC "${CC_REPO_DIR}" "${CC_NAME}" "${CC_VERSION}" "node"

if [[ ! -f "${CC_NAME}@${CC_VERSION}.tgz" ]];then
    fatalln "${CC_NAME}@${CC_VERSION}.tgz not created by packageCC"
fi

