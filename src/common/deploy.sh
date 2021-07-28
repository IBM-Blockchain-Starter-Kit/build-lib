#!/usr/bin/env bash

# Common deploy script for chaincode
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain.sh"

function deploy_cc() {
  local platform=$1
  local chaincode_dir_prefix=$2

  if [[ ! -f $CONFIGPATH ]]; then
    echo "No deploy configuration at specified path: ${CONFIGPATH}"
    exit 1
  fi

  echo "======== Validating dependencies ========"
  nvm_install_node "${NODE_VERSION}"

  echo "-------- Building Fabric-Cli --------"
  build_fabric_cli "${FABRIC_CLI_DIR}"

  echo "-------- Installing jq --------"
  install_jq

  # Load profiles from toolchain ENV variables (from creation)
  echo "======== Loading identity profiles and certificates ========"
  PROFILES_PATH=$(mktemp -d)
  mkdir -p "${PROFILES_PATH}"

  # Handle single identity/certificate or an array of information
  if [[ ${ADMIN_IDENTITY_STRING::1} != "[" ]]; then
    ADMIN_IDENTITY_STRING=["$ADMIN_IDENTITY_STRING"]
  fi
  for IDENTITYINDEX in $(jq -n "${ADMIN_IDENTITY_STRING}" | jq -r "keys | .[]"); do
    jq -n "${ADMIN_IDENTITY_STRING}" | jq -r ".[$IDENTITYINDEX]" | tee "${PROFILES_PATH}/ADMINIDENTITY_${IDENTITYINDEX}.json"

    echo "-> ${PROFILES_PATH}/ADMINIDENTITY_${IDENTITYINDEX}.json"
  done

  if [[ ${CONNECTION_PROFILE_STRING::1} != "[" ]]; then
    CONNECTION_PROFILE_STRING=["$CONNECTION_PROFILE_STRING"]
  fi
  for PROFILEINDEX in $(jq -n "${CONNECTION_PROFILE_STRING}" | jq -r "keys | .[]"); do
    jq -n "${CONNECTION_PROFILE_STRING}" | jq -r ".[$PROFILEINDEX]" | tee "${PROFILES_PATH}/CONNPROFILE_${PROFILEINDEX}.json"

    echo "-> ${PROFILES_PATH}/CONNPROFILE_${PROFILEINDEX}.json"
  done

  # Deploying based on configuration options
  echo "======== Reading 'deploy_config.json' ========"
  ORGINDEX=0
  ECODE=1
  CC_VERSION="$(date '+%Y%m%d.%H%M%S')"

  for ORG in $(jq -r "keys | .[]" "${CONFIGPATH}"); do
    for CCINDEX in $(jq -r ".[\"${ORG}\"].chaincode | keys | .[]" "${CONFIGPATH}"); do
      CC=$(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}]" "${CONFIGPATH}")

      # Collect chaincode metadata
      CC_NAME=$(jq -n "${CC}" | jq -r '.name')
      json_version=$(jq -n "${CC}" | jq -r '.version?')
      if [[ $json_version != null && $json_version != "" ]]; then
        CC_VERSION=$json_version
      fi
      CC_SRC=$(jq -n "${CC}" | jq -r '.path')

      ADMIN_IDENTITY_FILE="${PROFILES_PATH}/ADMINIDENTITY_${ORGINDEX}.json"
      CONN_PROFILE_FILE="${PROFILES_PATH}/CONNPROFILE_${ORGINDEX}.json"

      # Should install
      if [[ "true" == $(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .install" "${CONFIGPATH}") ]]; then

        if [ -z "${chaincode_dir_prefix}" ]; then
          local cc_dir="${CC_SRC}"
        else
          local cc_dir="${chaincode_dir_prefix}/${CC_SRC}"
        fi

        install_fabric_chaincode "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" \
          "${CC_NAME}" "${CC_VERSION}" "${platform}" "${cc_dir}"
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

          if [[ -n "${collections_config}" ]]; then
            #collections config must be in the same directory as the chaincode plus any additional path specified by user
            collections_config="${cc_dir}/${collections_config}"
          fi

          endorsement_policy=$(jq -r ".[\"${ORG}\"].chaincode | .[${CCINDEX}] | .endorsement_policy?" "${CONFIGPATH}")
          if [[ $endorsement_policy == null ]]; then unset endorsement_policy; fi

          instantiate_fabric_chaincode "${ORG}" "${ADMIN_IDENTITY_FILE}" "${CONN_PROFILE_FILE}" \
            "${CC_NAME}" "${CC_VERSION}" "${CHANNEL}" "${platform}" "${init_fn}" "${init_args}" "${collections_config}" "${endorsement_policy}"
        fi
      done
    done
    ORGINDEX=$((ORGINDEX + 1))
  done

  rm -rf "${PROFILES_PATH}"

  if [[ ! $ECODE ]]; then error_exit "ERROR: please check the deploy_config.json to set deploy jobs"; fi
}


