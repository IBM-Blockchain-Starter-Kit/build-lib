
export ENABLE_PEER_CLI=true
# Common deploy script for chaincode
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain.sh"

## If CC_PACKAGE_LOCATION is set, use location or default to root dir
CC_PACKAGE_LOCATION=${CC_PACKAGE_LOCATION:-"${ROOTDIR}/${CC_NAME}@${CC_VERSION}.tgz"}

: "${CC_REPO_DIR:?"CC_REPO_DIR not set" }"
: "${CC_NAME:?"CC_NAME not set" }"
: "${CC_VERSION:?"CC_VERSION not set" }"
: "${PEERS_COUNT:?"PEERS_COUNT not set" }"
: "${CHANNEL_NAME:?"CHANNEL_NAME not set" }"
: "${CC_PACKAGE_LOCATION:?"CC_PACKAGE_LOCATION not set" }"
#: "${CC_SEQUENCE:?"CC_SEQUENCE not set" }"
verifyPeerEnv

#TODO make available v2.x functions such as sequence
#todo queryInstalled first to make sure we dont need to install
if [[ ${INSTALL_OVERRIDE_SKIP} == "false" ]];then
    installChaincode_v2 "${CC_PACKAGE_LOCATION}"
fi