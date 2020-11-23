#!/usr/bin/env bash

echo "######## Build chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x

echo "======== Verify Env Variables ========"
echo "CC_REPO_DIR: $CC_REPO_DIR"
ls -agln "$CC_REPO_DIR"

echo "======== Download dependencies ========"
setup_env
install_python "${PYTHON_VERSION}"
# echo "Y" | apt-get install python2.7
nvm_install_node "${NODE_VERSION}"

echo "======== Building fabric-cli tool ========"
cd "${FABRIC_CLI_DIR}" || exit 1
npm install
npm run build
# npm link

echo "======== Building chaincode ========"
install_jq
##TODO fail on error, because jq is piped below, it doesn't fail if jq errors
for org in $(jq -r "keys | .[]" "${CONFIGPATH}"); do
  for cc_path in $(jq -r ".${org}.chaincode | .[] | .path" "${CONFIGPATH}"); do    
    echo "Processing path: ${cc_path}"
    cd "${CC_REPO_DIR}/${cc_path}" || exit 1
    npm install
    npm run build # transpile from typescript to javascript
  done
done

## cd "$CC_REPO_DIR" || exit 1
## npm install
## npm run build # transpile from typescript to javascript
