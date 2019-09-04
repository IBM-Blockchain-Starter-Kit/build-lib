#!/usr/bin/env bash

echo "######## Test chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
source "${SCRIPT_DIR}/common/blockchain.sh"

$DEBUG && set -x

echo "######## Download dependencies ########"

install_node "$NODE_VERSION" "$NVM_VERSION"
npm install
npm run build

echo "######## Run cc tests ########"

npm run test

# echo "######## Run deploy_config tests ########"

# if [[ -z $(command -v jq) ]]; then
#     install_jq
# fi

# for component in $(cat ${CONFIGPATH} | jq -r "keys | .[]"); do
#     validate_component "https://8eed4b94936d41a6aac17bdac8a2d7f8-optools.uss02.blockchain.cloud.ibm.com" \
#         "mSeo7VrFtt228viF1tWniIFbp4w21NynnXV7rB6eVFZn" ${component}
# done
