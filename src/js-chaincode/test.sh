#!/usr/bin/env bash

echo "######## Test chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# shellcheck source=src/common/blockchain.sh
source "${SCRIPT_DIR}/common/blockchain.sh"

$DEBUG && set -x
## cd "$CC_REPO_DIR" || exit 1

echo "======== Download dependencies ========"
nvm_install_node "${NODE_VERSION}"
install_jq

echo "======== Run cc tests ========"
THIS_DIR="$PWD"
for org in $(jq -r "keys | .[]" "${CONFIGPATH}"); do
  for cc_path in $(jq -r ".${org}.chaincode | .[] | .path" "${CONFIGPATH}"); do    
    echo "Processing Tests on Path: ${cc_path}"
    cd "${CC_REPO_DIR}/${cc_path}" || exit 1
    npm run test
  done
done
cd "$THIS_DIR" || exit 1


echo "======== Run deploy_config.json tests ========"
# convert strings (if only one element) into array
if [[ ${ADMIN_IDENTITY_STRING::1} != "[" ]]; then
    ADMIN_IDENTITY_STRING=["${ADMIN_IDENTITY_STRING}"]
fi
if [[ ${CONNECTION_PROFILE_STRING::1} != "[" ]]; then
    CONNECTION_PROFILE_STRING=["${CONNECTION_PROFILE_STRING}"]
fi

# check same number of identities + profiles + deploy orgs defined
hm_adminids=$(jq -n "${ADMIN_IDENTITY_STRING}" | jq -r "keys | length")
hm_connprofs=$(jq -n "${CONNECTION_PROFILE_STRING}" | jq -r "keys | length")
hm_orgs=$(jq "keys | length" "$CONFIGPATH")

if [[ "${hm_adminids}" != "${hm_connprofs}" ]]; then
    error_exit "number of ADMIN IDENTITIES does not match the number of CONNECTION PROFILES"
fi
