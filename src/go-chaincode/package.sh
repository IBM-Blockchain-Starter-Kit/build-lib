
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

# Find an existing cc namespace
if [[ "${HLF_VERSION}" == "2."* ]]; then
  queryCommitted
  if [[ -z $LATEST_SEQ ]];then
      # Did not find last seq therefore define
      export LATEST_SEQ=0
  fi
  #rm last entry
  awk '!/LATEST_SEQ/' build.properties > temp && mv temp build.properties
  echo "LATEST_SEQ=${LATEST_SEQ}" >> build.properties
  export CC_SEQUENCE=${CC_SEQUENCE_OVERRIDE:-$(expr $LATEST_SEQ + 1)}
fi

# Update package.json cc name and version
cd "${CC_REPO_DIR}"
##Update CC_VERSION for go package if any
#npm version prerelease --preid="${CC_VERSION}"
cd -

packageCC "${CC_REPO_DIR}" "${CC_NAME}" "${CC_VERSION}" "${CC_SEQUENCE}" "golang"

if [[ ! -f "${CC_NAME}@${CC_VERSION}.tgz" ]];then
    fatalln "${CC_NAME}@${CC_VERSION}.tgz not created by packageCC"
fi
