#!/usr/bin/env bash

echo "######## Build chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

$DEBUG && set -x

echo "######## Download dependencies ########"
nvm_install_node $NODE_VERSION
# setup_env



echo "######## Print Environment ########"

# /root
echo "=> HOME ${HOME}"
ls -aGln $HOME

# /home/pipeline/...
echo "=> ROOT ${ROOTDIR}"
ls -aGln $ROOTDIR


# echo "######## Building chaincode ########"

# npm install
# npm run build
