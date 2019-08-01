#!/usr/bin/env bash

# Go chaincode specific deploy script

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

echo "######## Download dependencies ########"
setup_env
install_python $PYTHON_VERSION
nvm_install_node $NODE_VERSION
install_jq
echo

echo "######## Build fabric-cli ########"
build_fabric_cli $FABRIC_CLI_DIR
echo

echo "=> Validating dependencies..."
if [[ ! -n $(command -v fabric-cli) ]]; then
  exit_error "fabric-cli interface not found in PATH env variable"
else
  which fabric-cli
fi
if [[ ! -n $(command -v jq) ]]; then
  exit_error "jq interface not found in PATH env variable"
else
  which jq
fi

echo '$CONFIGPATH...'${CONFIGPATH}
cat ${CONFIGPATH}
CONFIGPATH="$(pwd)/deploy_config.json"
CONFIG=`cat ${CONFIGPATH}`
echo $CONFIG; echo; echo;

install_cc "${CONFIGPATH}" "node" $(pwd)
instantiate_cc "${CONFIGPATH}" "node" $(pwd)
invoke_cc "${CONFIGPATH}" "node" $(pwd)

####################################
#!/usr/bin/env bash

# source "${SCRIPT_DIR}/common/env.sh"
# source "${SCRIPT_DIR}/common/util.sh"
# source "${SCRIPT_DIR}/common/blockchain-v2.sh"
# source "config/blockchain-v2.sh"

## TEST:


# if [[ ! -n $(command -v fabric-cli) ]]; then
#   exit_error "fabric-cli interface not found in PATH env variable"
# fi
# if [[ ! -n $(command -v jq) ]]; then
#   exit_error "jq interface not found in PATH env variable"
# fi




# # echo $(dirname $0)

# # for org in $(echo $CONFIG | jq 'keys | .[]'); do
# #   echo $org
# # done


# # Install chaincode for all orgs' peers
# if [[ -z $1 || $1 == "install" ]]; then
# fi

# # Instantiate chaincode in channels
# if [[ -z $1 || $1 == "instantiate" ]]; then
#   instantiate_cc "${CONFIG}" node $(pwd)
# fi

# # Invoke init func on installed channels by installed organizations
# if [[ -z $1 || $1 == "invoke" ]]; then
#   invoke_cc "${CONFIG}" node $(pwd)
# fi
####################################