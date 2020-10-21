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

verifyPeerEnv
## Need to remove the danm node_modules
rm -rf "${CC_REPO_DIR}/node_modules"

# Find an existing cc namespace
queryCommitted
if [[ -z $LATEST_SEQ ]];then
    # Did not find last seq therefore define
    export LATEST_SEQ=1
fi

#rm last entry
awk '!/LATEST_SEQ/' build.properties > temp && mv temp build.properties
echo "LATEST_SEQ=${LATEST_SEQ}" >> build.properties

export CC_SEQUENCE=$(expr $LATEST_SEQ + 1)

packageCC "${CC_REPO_DIR}" "${CC_NAME}" "${CC_VERSION}" "${CC_SEQUENCE}" "node"

if [[ ! -f "${CC_NAME}@${CC_VERSION}-${CC_SEQUENCE}.tgz" ]];then
    fatalln "${CC_NAME}@${CC_VERSION}-${CC_SEQUENCE}.tgz not created by packageCC"
fi
