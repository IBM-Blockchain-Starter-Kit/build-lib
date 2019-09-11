#!/usr/bin/env bash

# JS chaincode specific deploy script

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

echo "======== Validating dependencies ========"
nvm_install_node ${NODE_VERSION}
if [[ -z $(command -v fabric-cli) ]]; then
  echo "-------- Building Fabric-Cli --------"
  build_fabric_cli ${FABRIC_CLI_DIR}
fi
if [[ -z $(command -v jq) ]]; then
  echo "-------- Installing jq --------"
  install_jq
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

EXIT_CODE=1
for ORG in $(cat ${CONFIGPATH} | jq -r 'keys | .[]'); do    
  for CCINDEX in $(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | keys | .[]' ); do        
    CC=$(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}']' )    

    # collect chaincode metadata
    CC_NAME=$(echo ${CC} | jq -r '.name')    
    CC_VERSION="$(date '+%Y%m%d.%H%M%S')"
    json_version=$(echo ${CC} | jq -r '.version?')
    if [[ $json_version != null && $json_version != "" ]]; then
        CC_VERSION=$json_version
    fi
    echo "check condition"...$(echo ${CC} | jq -r '.version?')
    echo "CC_VERSION"...$CC_VERSION

    # should install
    if [[ "true" == $(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}'] | .install' ) ]]; then
        retry_with_backoff 5 install_fabric_chaincode "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" "${CC_NAME}" "${CC_VERSION}" "node" "${CHAINCODEPATH}"
    fi

    for CHANNEL in $(echo ${CC} | jq -r '.channels | .[]'); do
      # should instantiate
      if [[ "true" == $(cat ${CONFIGPATH} | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}'] | .instantiate' ) ]]; then
        init_fn=$(cat $CONFIGPATH | jq -r '.['\"${ORG}\"'].chaincode | .['${CCINDEX}'] | .init_fn?')
        if [[ $init_fn == null ]]; then unset init_fn; fi

        init_args=$(cat $CONFIGPATH | jq -r '.['\"${org}\"'].chaincode | .['${CCINDEX}'] | .init_args?')
        if [[ $init_args == null ]]; then unset init_args; fi

        collections_config=$(cat $CONFIGPATH | jq -r '.['\"${org}\"'].chaincode | .['${CCINDEX}'] | .collections_config?')
        if [[ $collections_config == null ]]; then unset collections_config; fi

        retry_with_backoff 5 instantiate_fabric_chaincode "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" "${CC_NAME}" "${CC_VERSION}" "${CHANNEL}" "node" "${init_fn}" "${init_args}" "${collections_config}"

        EXIT_CODE=0
      fi      
    done
  done
done

rm -rf "${PROFILES_PATH}"

exit $EXIT_CODE