#!/usr/bin/env bash

echo "######## Test chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
source "${SCRIPT_DIR}/common/blockchain.sh"

$DEBUG && set -x
cd $CHAINCODEPATH

echo "======== Download dependencies ========"
nvm_install_node "$NODE_VERSION"
install_jq

echo "======== Run cc tests ========"
npm run test

echo "======== Run deploy_config.json tests ========"
# convert strings into array
if [[ ${ADMIN_IDENTITY_STRING::1} == "[" ]]; then
    # check same number of identities + profiles defined
    hm_adminids=$(echo $ADMIN_IDENTITY_STRING | jq "keys | length")
    hm_connprofs=$(echo $CONNECTION_PROFILE_STRING | jq "keys | length")
    if [[ $hm_adminids != $hm_connprofs ]]; then
        error_exit "number of ADMIN IDENTITIES does not match the number of CONNECTION PROFILES"
    fi

    hm_orgs=$(cat $CONFIGPATH | jq "keys | length")
    if [[ $hm_adminids != $hm_orgs ]]; then
        error_exit "number of ADMIN IDENTITIES does not match the number of ORGANIZATIONS defined in the deploy_config.json file"    
    fi
fi