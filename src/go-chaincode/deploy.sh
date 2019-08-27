#!/usr/bin/env bash

# Go chaincode specific deploy script

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain-v2.sh"

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

profiles_path=$(pwd)/profiles/
mkdir -p "${profiles_path}"

conn_profile_file=$(pwd)/profiles/conn_profile_file.json
admin_identity_file=$(pwd)/profiles/admin_identity_file.json


# Deploying based on configuration options
echo "######### Reading 'deploy_config.json' for deployment options #########"

for org in $(cat ${CONFIGPATH} | jq 'keys | .[]'); do
  for ccindex in $(cat ${CONFIGPATH} | jq ".${org}.chaincode | keys | .[]"); do
    cc=$(cat ${CONFIGPATH} | jq ".${org}.chaincode | .[${ccindex}]")
    for channel in $(echo ${cc} | jq '.channels | .[]'); do
    #   conn_profile="$(pwd)/config/${org}-${channel}.json"
    #   admin_identity="$(pwd)/config/${org}-admin.json"
      cc_name=$(echo ${cc} | jq -r '.name')
      cc_version=$(echo ${cc} | jq -r '.version')
      cc_src=$(echo ${cc} | jq -r '.path')

      # check chaincode path exists in GOPATH/src directory
      echo "-> reviewing chaincode path...${cc_src}"
      ls ${GOPATH}/src/${cc_src}
      if [[! -n $(ls ${GOPATH}/src/${cc_src}) ]]; then
        error_exit "cannot locate chaincode path for ${cc_src}"
      fi

      # should install
      if [[ "true" == $(cat ${CONFIGPATH} | jq -r ".${org}.chaincode | .[${ccindex}] | .install") ]]; then
        echo "=> installing...${cc_src}"
        retry_with_backoff 5 install_cc "${org}" "${admin_identity_file}" "${conn_profile_file}" "${cc_name}" "${cc_version}" "golang" ${cc_src}
      fi

      # should instantiate
      if [[ "true" == $(cat ${CONFIGPATH} | jq ".${org}.chaincode | .[${ccindex}] | .instantiate") ]]; then
        init_fn=$(cat $CONFIGPATH | jq ".${org}.chaincode | .[${ccindex}] | .init_fn?")
        if [[ -z $init_fn ]]; then init_fn="init"; fi

        init_args=$(cat $CONFIGPATH | jq ".${org}.chaincode | .[${ccindex}] | .init_args?")
        if [[ -z $init_args ]]; then init_args="[]"; fi

        echo "=> instantiating...${cc_src}"
        retry_with_backoff 5 instantiate_cc "${org}" "${admin_identity_file}" "${conn_profile_file}" "${cc_name}" "${cc_version}" "${channel}" "golang" "${init_fn}" "${init_args}"

        # # test invokation of init method
        # invoke_cc $org $admin_identity
      fi
    done
  done
done

# setup_service_constants
# provision_blockchain
# fetch_dependencies $CONFIGPATH
# deploy_fabric_chaincode golang $CONFIGPATH