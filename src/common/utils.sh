#!/usr/bin/env bash
#
# Common utility functions, e.g. to make curl requests

## Logging helpers
source <(curl -sSL https://raw.githubusercontent.com/hyperledger/fabric-samples/master/test-network/scriptUtils.sh)

#######################################
# Exit script with an error
# Globals:
#   None
# Arguments:
#   message: Optional error message
# Returns:
#   None
#######################################
function error_exit {
  echo "${1:-"Unknown Error"}" 1>&2
  exit 1
}

#######################################
# Installs jq using curl and updates path
# Globals:
#   set: PATH
# Arguments:
#   None
# Returns:
#   None
#######################################
function install_jq {
  curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
  chmod +x jq
  export PATH=${PATH}:${PWD}
}

#######################################
# Installs fabric binaries v2
# Globals:
#   set: PATH
# Arguments:
#   None
# Returns:
#   None
#######################################
function install_fabric_bin {
    #TODO make version dynamic
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.1.1 1.4.9 -d -s
    chmod +x bin/configtxgen
    chmod +x bin/idemixgen
    chmod +x bin/configtxlator
    chmod +x bin/fabric-ca-client
    chmod +x bin/orderer
    chmod +x bin/peer
    export FABRIC_CFG_PATH=${PWD}/config
    export PATH=${PATH}:${PWD}
}

#######################################
# Installs node using nvm
# Globals:
#   None
# Arguments:
#   NODE_VERSION:   Version of Node.js to install
#   NVM_VERSION:    Version of NVM to install
# Returns:
#   None
#######################################
function install_node {
  local NODE_VERSION=$1
  local NVM_VERSION=$2

  echo "=> Installing Node.js version ${NODE_VERSION} using nvm ${NVM_VERSION} ..."
  # Can safely ignore nvm.sh since it's not ours
  # shellcheck disable=SC1090
  
  npm config delete prefix \
    && curl "https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh" | bash \
    && . "$HOME/.nvm/nvm.sh" \
    && nvm alias default "$NODE_VERSION" \
    && nvm use default \
    && node -v \
    && npm -v
}

function nvm_install_node {
  local NODE_VERSION=${1-:NODE_VERSION}

  echo "=> Installing Node.js version ${NODE_VERSION} using nvm $(nvm --version) ..."

  if [[ $(nvm ls) == *"$NODE_VERSION"* ]]; then
    echo "node v$NODE_VERSION found"
  else
    echo "node v$NODE_VERSION not found"
  fi

  nvm install "$NODE_VERSION" \
    && nvm alias default "$NODE_VERSION" \
    && nvm use default \
    && nvm current \
    && node -v \
    && npm -v
}

#######################################
# Installs python via curl
# Globals:
#   None
# Arguments:
#   PYTHON_VERSION: Version of Node.js to install
# Returns:
#   None
#######################################
function install_python {
  local PYTHON_VERSION=$1
  if [ -n "$PYTHONPATH" ]; then
    export PYTHONPATH=/opt/python/$PYTHON_VERSION
  fi    

  pushd "$(pwd)" || exit
  
  echo "=> Installing Python-v${PYTHON_VERSION} ..."
  # echo '$PYTHONPATH'...${PYTHONPATH}

  python_dir=$(mktemp -d) || exit
  
  cd "${python_dir}" \
    && curl  "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" > "Python-${PYTHON_VERSION}.tgz" \
    && tar -xzvf "Python-${PYTHON_VERSION}.tgz"  \
    && cd "Python-${PYTHON_VERSION}" \
    && ./configure "--prefix=${PYTHONPATH}" "--enable-optimizations" \
    && make install

  rm -rf "${python_dir}"

  link_python "${PYTHONPATH}"
  
  popd || exit
}

#######################################
# Relinks python by updating PATH variable
# Globals:
#   None
# Arguments:
#   PYTHON_VERSION: Version of Node.js to install
# Returns:
#   None
#######################################
function link_python {
    local PYTHONPATH=$1

    export PATH=${PYTHONPATH}/bin:$PATH
    echo "export PATH=${PYTHONPATH}/bin:$PATH" >> "${HOME}/.bashrc"
}

#######################################
# Builds fabric-cli in env set $FABRIC_CLI_DIR path
# Globals:
#   set: PATH
# Arguments:
#   None
# Returns:
#   None
#######################################
function build_fabric_cli {
  local BUILD_DIR=${1:-$FABRIC_CLI_DIR}

  pushd "$(pwd)" || exit
  cd "$BUILD_DIR" || exit

  npm install
  npm run build
  npm link

  popd || exit
}

#######################################
# Performs curl request, displays response, and returns status
# Globals:
#   None
# Arguments:
#   $@: Curl options
# Returns:
#   err_no:
#     0 = http status code is between 200 and 299 inclusive, indicating success
#     1 = http status code is less than 200, indicating an informational response, or
#         greater than 299, indicating redirection or error
#######################################
function do_curl {
  HTTP_RESPONSE=$(mktemp)
  HTTP_STATUS=$(curl -w '%{http_code}' -o "${HTTP_RESPONSE}" "$@")
  cat "${HTTP_RESPONSE}"
  rm -f "${HTTP_RESPONSE}"
  if [[ ${HTTP_STATUS} -ge 200 && ${HTTP_STATUS} -lt 300 ]]
  then
    return 0
  else
    return 1
  fi
}

#######################################
# Retries a command until it succeeds, with an increasing delay between each attempt
# Globals:
#   None
# Arguments:
#   max_attempts: maximum number of times to retry the command
#   command: command to run
# Returns:
#   exitCode: the exit code of the last attempt
#######################################
function retry_with_backoff {
  local attempt=1
  local max_attempts=5
  local timeout=1
  local exitCode=0

  if [ "$1" -gt 0 ]; then
    max_attempts="$1"
  fi
  shift

  while : ; do
    "$@"
    exitCode=$?

    if [ "$exitCode" -ne 0 ] && [ "$attempt" -lt "$max_attempts" ]; then
      sleep $timeout
      attempt=$(( attempt + 1 ))
      timeout=$(( timeout * 2 ))
    else
      return $exitCode
    fi
  done
}

#######################################
# Download and install ubuntu build-essential package
#######################################
function setup_env {
  # sudo add-apt-repository ppa:saiarcot895/myppa
  # sudo apt-get update
  # sudo apt-get -y install apt-fast

  echo "=> apt-get update"
  if [[ ! $DEBUG ]]; then
    apt-get -y update > /dev/null
  else
    apt-get -y update
  fi
  echo

  echo "=> apt-get install build-essential"
  echo " (usually takes a few minutes...)"
  if [[ ! $DEBUG ]]; then
    apt-get -y install build-essential --fix-missing > /dev/null
  else
    apt-get -y install build-essential --fix-missing
  fi
  echo

  # echo "=> apt install g++" 
  # echo "Y" | apt install g++ --fix-missing
  # echo

  # echo "=> apt-get install python2.7" 
  # echo "Y" | apt-get install python2.7 --fix-missing > /dev/null
  # echo
  # echo 'which python'...`which python`
  # echo 'npm config get python'...`npm config get python`

}

verifyPeerEnv(){
    if [[ -z $ORDERER_PEM ]];then
        warnln "ORDERER_PEM not set. Please make sure Peer env is set correctly"
    elif [[ -z $CORE_PEER_TLS_ROOTCERT_FILE ]];then
        warnln "CORE_PEER_TLS_ROOTCERT_FILE not set. Please make sure Peer env is set correctly"
    elif [[ -z $CORE_PEER_ADDRESS ]];then
        warnln "CORE_PEER_ADDRESS not set. Please make sure Peer env is set correctly"
    fi

    if [[ -z $CORE_PEER_LOCALMSPID ]];then
        fatalln "CORE_PEER_LOCALMSPID not set. Please make sure Peer env is set correctly"
    elif [[ -z $CORE_PEER_MSPCONFIGPATH ]];then
        fatalln "CORE_PEER_MSPCONFIGPATH not set. Please make sure Peer env is set correctly"
    elif [[ -z $FABRIC_CFG_PATH ]];then
        fatalln "FABRIC_CFG_PATH not set. Please make sure Peer env is set correctly"
    fi
}

