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
PROFILES_PATH=$(mktemp -d)
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
ECODE=1
for ORG in $(jq -r "keys | .[]" "${CONFIGPATH}"); do    
  for CCINDEX in $(jq -r ".[\"${ORG}\"].chaincode | keys | .[]" "${CONFIGPATH}"); do
    CC=$(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}]" "${CONFIGPATH}")        

    # collect chaincode metadata
    CC_NAME=$(jq -n "${CC}" | jq -r '.name')
    CC_VERSION="$(date '+%Y%m%d.%H%M%S')"
    json_version=$(jq -n "${CC}" | jq -r '.version?')
    if [[ $json_version != null && $json_version != "" ]]; then
        CC_VERSION=$json_version
    fi

    ADMIN_IDENTITY_FILE="${PROFILES_PATH}/ADMINIDENTITY_0.json"
    CONN_PROFILE_FILE="${PROFILES_PATH}/CONNPROFILE_0.json"


    # should install
    if [[ "true" == $(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .install" "${CONFIGPATH}") ]]; then
        install_fabric_chaincode "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" \
          "${CC_NAME}" "${CC_VERSION}" "node" "$CHAINCODEPATH"
    fi

    ECODE=0

    for CHANNEL in $(jq -n "${CC}" | jq -r '.channels | .[]'); do
      # should instantiate
      if [[ "true" == $(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .instantiate" "${CONFIGPATH}") ]]; then
        init_fn=$(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .init_fn?" "${CONFIGPATH}")
        if [[ $init_fn == null ]]; then unset init_fn; fi

        init_args=$(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .init_args?" "${CONFIGPATH}")
        if [[ $init_args == null ]]; then unset init_args; fi

        collections_config=$(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .collections_config?" "${CONFIGPATH}")
        if [[ $collections_config == null ]]; then unset collections_config; fi

        instantiate_fabric_chaincode "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" \
          "${CC_NAME}" "${CC_VERSION}" "${CHANNEL}" "node" "${init_fn}" "${init_args}" "${collections_config}"
      fi      
    done
  done
done

rm -rf "${PROFILES_PATH}"

if [[ ! $ECODE ]]; then error_exit "ERROR: please check the deploy_config.json to set deploy jobs"; fi