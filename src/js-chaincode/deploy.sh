#!/usr/bin/env bash

# JS chaincode specific deploy script

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain-v2.sh"

$DEBUG && set -x

if [[ ! -f $CONFIGPATH ]]; then
  echo "No deploy configuration at specified path: ${CONFIGPATH}"
  exit 1
fi

# echo "######## Download dependencies ########"
# setup_env
nvm_install_node $NODE_VERSION
install_jq
# echo

echo "######## Build fabric-cli ########"
build_fabric_cli $FABRIC_CLI_DIR
echo

echo "=> Validating dependencies..."
if [[ ! -n $(command -v fabric-cli) ]]; then
  error_exit "fabric-cli interface not found in PATH env variable"
else
  which fabric-cli
fi
if [[ ! -n $(command -v jq) ]]; then
  error_exit "jq interface not found in PATH env variable"
else
  which jq
fi

echo '$CONFIGPATH...'${CONFIGPATH}

for org in $(cat ${CONFIGPATH} | jq -r 'keys | .[]'); do
  for ccindex in $(cat ${CONFIGPATH} | jq -r ".${org}.chaincode | keys | .[]"); do
    cc=$(cat ${CONFIGPATH} | jq -r ".${org}.chaincode | .[${ccindex}]")
    for channel in $(echo ${cc} | jq -r '.channels | .[]'); do
      conn_profile="$(pwd)/config/${org}-${channel}.json"
      admin_identity="$(pwd)/config/${org}-admin.json"
      cc_name=$(echo ${cc} | jq -r '.name')
      cc_version=$(echo ${cc} | jq -r '.version')

      # should install
      if [[ "true" == $(cat ${CONFIGPATH} | jq -r ".${org}.chaincode | .[${ccindex}] | .install") ]]; then
        retry_with_backoff 5 install_cc "${org}" "${admin_identity}" "${conn_profile}" "${cc_name}" "${cc_version}" "node" "$(pwd)"
      fi

      # should instantiate
      if [[ "true" == $(cat ${CONFIGPATH} | jq -r ".${org}.chaincode | .[${ccindex}] | .instantiate") ]]; then
        init_fn=$(cat $CONFIGPATH | jq -r ".${org}.chaincode | .[${ccindex}] | .init_fn?")
        if [[ $init_fn == null ]]; then unset init_fn; fi

        init_args=$(cat $CONFIGPATH | jq -r ".${org}.chaincode | .[${ccindex}] | .init_args?")
        if [[ $init_args == null ]]; then unset init_args; fi

        collections_config=$(cat $CONFIGPATH | jq -r ".${org}.chaincode | .[${ccindex}] .collections_config?")
        if [[ $collections_config == null ]]; then unset collections_config; fi

        retry_with_backoff 5 instantiate_cc "${org}" "${admin_identity}" "${conn_profile}" "${cc_name}" "${cc_version}" "${channel}" "node" "${init_fn}" "${init_args}" "${collections_config}"

        # test invocation of init method
        # invoke_cc $org $admin_identity
      fi
    done
  done
done
