#!/usr/bin/env bash
#
# Common utility functions, e.g. to make curl requests

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
# Creates and displays a name that is likely to be unique and suitable for use
# when deploying apps to bluemix
# Globals:
#   None
# Arguments:
#   uuid: Universally unique identifier
#   name: Additional name arguments
# Returns:
#   None
#######################################
function get_deploy_name {
  uuid="${1:?get_deploy_name must be called with at least one argument}"
  shift

  old_ifs="$IFS"
  IFS='_'
  name="$*"
  IFS=$old_ifs

  unique_name="${name}_${uuid}"

  short_hash=$(echo "${unique_name}" | git hash-object --stdin | head -c 7)

  deploy_name=$(echo "${name}" | head -c 43)${short_hash}
  echo "${deploy_name}"
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

  echo "######## Installing Node.js version ${NODE_VERSION} using nvm ${NVM_VERSION} ########"
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

  echo "######## Installing Node.js version ${NODE_VERSION} using nvm $(nvm --version) ########"
  
  nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
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
  local PYTHON_PATH=$HOME/python
  local PREVDIR=$(pwd)

  echo "######## Installing Python-v${PYTHON_VERSION} ########"
  echo '=> $PYTHON_PATH'...${PYTHON_PATH}

  python_dir=$(mktemp -d) \
    && cd $python_dir \
    && curl  "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" > Python-${PYTHON_VERSION}.tgz \
    && tar -xzvf Python-${PYTHON_VERSION}.tgz  \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --prefix=${PYTHON_PATH} --enable-optimizations \
    && make install

  link_python ${PYTHON_PATH}

  echo '$PYTHON_PATH'...
  ls -agln $PYTHON_PATH/bin

  # echo "export PATH=${HOME}/.python/bin:$PATH" >> ${HOME}/.bashrc
  # source ~/.bashrc

  cd $PREVDIR
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
    local PYTHON_PATH=$1

    export PATH=${PYTHON_PATH}/bin:$PATH
    echo "export PATH=${PYTHON_PATH}/bin:$PATH" >> ${HOME}/.bashrc
    
    # echo '$PATH'...$PATH
    # echo '$PYTHON'...`python --version`
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

  local PREVDIR=$(pwd)
  cd $BUILD_DIR

  echo "######## Building fabric-cli ########"
  
  echo "=> npm -v ... $(npm -v)"
  npm install
  echo "=> npm run build..."
  npm run build
  echo "=> npm link..."
  npm link

  cd $PREVDIR
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
# Download and install
#   - gcc compiler
#   - make binaries
#######################################
function setup_env {
  echo "=> apt-get update"
  echo "Y" | apt-get update
  echo

  echo "=> apt-get install build-essential"
  echo " (usually takes a few minutes...)"
  echo "Y" | apt-get install build-essential --fix-missing
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
