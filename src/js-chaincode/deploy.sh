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
echo "======== Loading identity profiles and certificates ========"
PROFILES_PATH=$(pwd)/profiles
mkdir -p "${PROFILES_PATH}"

# handle single identity/certificate or an array of information
if [[ ${ADMIN_IDENTITY_STRING::1} != "[" ]]; then
    ADMIN_IDENTITY_STRING=[$ADMIN_IDENTITY_STRING]
fi
for IDENTITYINDEX in $(echo ${ADMIN_IDENTITY_STRING} | jq -r "keys | .[]"); do
    echo $(echo ${ADMIN_IDENTITY_STRING} | jq -r ".[$IDENTITYINDEX]") > "${PROFILES_PATH}/ADMINIDENTITY_${IDENTITYINDEX}.json"

    echo "-> ${PROFILES_PATH}/ADMINIDENTITY_${IDENTITYINDEX}.json"
done

if [[ ${CONNECTION_PROFILE_STRING::1} != "[" ]]; then
    CONNECTION_PROFILE_STRING=[$CONNECTION_PROFILE_STRING]
fi
for PROFILEINDEX in $(echo ${CONNECTION_PROFILE_STRING} | jq -r "keys | .[]"); do
    echo $(echo ${CONNECTION_PROFILE_STRING} | jq -r ".[$PROFILEINDEX]") > "${PROFILES_PATH}/CONNPROFILE_${PROFILEINDEX}.json"
    
    echo "-> ${PROFILES_PATH}/CONNPROFILE_${PROFILEINDEX}.json"
done


# Deploying based on configuration options
echo "======== Reading 'deploy_config.json' ========"

ORGINDEX=0
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
    
    ADMIN_IDENTITY_FILE="${PROFILES_PATH}/ADMINIDENTITY_${ORGINDEX}.json"    
    CONN_PROFILE_FILE="${PROFILES_PATH}/CONNPROFILE_${ORGINDEX}.json"


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
      fi      
    done
  done

  ORGINDEX=$(($ORGINDEX + 1))
done


rm -rf "${PROFILES_PATH}"