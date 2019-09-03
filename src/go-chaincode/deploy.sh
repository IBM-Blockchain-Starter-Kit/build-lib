#!/usr/bin/env bash

# Go chaincode specific deploy script

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain.sh"

source "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh"

$DEBUG && set -x

if [[ ! -f $CONFIGPATH ]]; then
  echo "No deploy configuration at specified path: ${CONFIGPATH}"
  exit 1
fi

echo "######## Download dependencies ########"
nvm_install_node $NODE_VERSION
install_jq

echo "######## Link fabric-cli ########"
build_fabric_cli $FABRIC_CLI_DIR

echo "=> Validating dependencies..."
if [[ ! -n $(command -v fabric-cli) ]]; then
  error_exit "fabric-cli interface not found in PATH env variable"
fi
if [[ ! -n $(command -v jq) ]]; then
  error_exit "jq interface not found in PATH env variable"
fi


# Load profiles from toolchain ENV variables (from creation)
PROFILES_PATH=$(pwd)/profiles
mkdir -p "${PROFILES_PATH}"

CONN_PROFILE_FILE=${PROFILES_PATH}/CONN_PROFILE.json
echo "${CONNECTION_PROFILE_STRING}" > "${CONN_PROFILE_FILE}"

ADMIN_IDENTITY_FILE=${PROFILES_PATH}/ADMIN_IDENTITY.json
echo "${ADMIN_IDENTITY_STRING}" > "${ADMIN_IDENTITY_FILE}"


# Deploying based on configuration options
echo "######### Reading 'deploy_config.json' for deployment options #########"

PARSED_DEPLOY_CONFIG=False
for ORG in $(cat ${CONFIGPATH} | jq -r 'keys | .[]'); do    
  for CCINDEX in $(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | keys | .[]' ); do        
    CC=$(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}']' )    

    # collect chaincode metadata
    CC_NAME=$(echo ${CC} | jq -r '.name')    
    CC_VERSION="$(date '+%Y%m%d.%H%M%S')"
    if [[ $(echo ${CC} | jq -r '.version?') != null ]]; then
        CC_VERSION=${CC_VERSION}-$(echo ${CC} | jq -r '.version?')
    fi
    CC_SRC=$(echo ${CC} | jq -r '.path')

    # should install
    if [[ "true" == $(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}'] | .install' ) ]]; then
        retry_with_backoff 5 install_cc "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" "${CC_NAME}" "${CC_VERSION}" "golang" "${CC_SRC}"
    fi

    for CHANNEL in $(echo ${CC} | jq -r '.channels | .[]'); do
      PARSED_DEPLOY_CONFIG=True

      # should instantiate
      if [[ "true" == $(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}'] | .instantiate' ) ]]; then
        init_fn=$(cat $CONFIGPATH | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}'] | .init_fn?')
        if [[ $init_fn == null ]]; then unset init_fn; fi

        init_args=$(cat $CONFIGPATH | jq -r '.['\"${org}\"'].chaincode | .['${CCINDEX}'] | .init_args?')
        if [[ $init_args == null ]]; then unset init_args; fi

        collections_config=$(cat $CONFIGPATH | jq -r '.['\"${org}\"'].chaincode | .['${CCINDEX}'] | .collections_config?')
        if [[ $collections_config == null ]]; then unset collections_config; fi

        retry_with_backoff 5 instantiate_cc "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" "${CC_NAME}" "${CC_VERSION}" "${CHANNEL}" "golang" "${init_fn}" "${init_args}" "${collections_config}"
      fi      
    done
  done
done

if [[ ! PARSED_DEPLOY_CONFIG ]]; then
    exit 1
fi


rm -rf "${PROFILES_PATH}"