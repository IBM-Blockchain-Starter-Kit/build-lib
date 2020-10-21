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
: "${PEERS_COUNT:?"PEERS_COUNT not set" }"
: "${CHANNEL_NAME:?"CHANNEL_NAME not set" }"
# retries used for checkCommitReadiness
export MAX_RETRY=3
export DELAY=3
verifyPeerEnv

queryInstalled

checkCommitReadiness

commitChaincodeDefinition

queryCommitted