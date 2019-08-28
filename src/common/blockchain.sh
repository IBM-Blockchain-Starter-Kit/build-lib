#!/usr/bin/env bash

#######################################
# Install chaincode on peer(s) provided specified parameters
# Globals:
#   None
# Arguments:
#   - $1: ORG: org msp name
#   - $2: ADMIN_IDENTITY: abs path to associated admin identity
#   - $3: CONN_PROFILE: abs path to the connection profile
#   - $4: CC_NAME: chaincode name to be installed
#   - $5: CC_VERSION: chaincode version to be installed
#   - $6: PLATFORM: [ golang, node, java ]
#   - $7: SRC_DIR: absolute path to chaincode directory
# Returns:
#   None
#######################################
function install_cc {
  local ORG=$1
  local ADMIN_IDENTITY=$2
  local CONN_PROFILE=$3
  local CC_NAME=$4
  local CC_VERSION=$5
  local PLATFORM=$6
  local SRC_DIR=$7

  CMD="fabric-cli chaincode install --conn-profile ${CONN_PROFILE} --org ${ORG} \
  --admin-identity ${ADMIN_IDENTITY} --cc-name ${CC_NAME} --cc-version ${CC_VERSION} \
  --cc-type ${PLATFORM} --src-dir ${SRC_DIR}"

  echo
  echo ${CMD}
  echo
  echo ${CMD} | bash
}


#######################################
# Instantiate chaincode function provided specified parameters
# Globals:
#   None
# Arguments:
#   -  $1: ORG: org msp name
#   -  $2: ADMIN_IDENTITY: abs path to associated admin identity
#   -  $3: CONN_PROFILE: abs path to the connection profile
#   -  $4: CC_NAME: chaincode name to be installed
#   -  $5: CC_VERSION: chaincode version to be installed
#   -  $6: CHANNEL: channel name that chaincode will be instantiated on
#   -  $7: PLATFORM: [ golang, node, java ]
#  (-) $8: INIT_FN: name of function to be instantiated on (default: init)
#  (-) $9: INIT_ARGS: args passed into the init function (default: [])
#  (-)$10: COLLECTIONS_CONFIG: JSON formatted string of private collections configuration
# Returns:
#   None
#######################################
function instantiate_cc {
  local ORG=$1
  local ADMIN_IDENTITY=$2
  local CONN_PROFILE=$3
  local CC_NAME=$4
  local CC_VERSION=$5
  local CHANNEL=$6
  local PLATFORM=$7
  local INIT_FN=${8:-""}
  local INIT_ARGS=${9:-""}
  local COLLECTIONS_CONFIG=${10:-""}

  local CMD="fabric-cli chaincode instantiate --conn-profile ${CONN_PROFILE} --org ${ORG} \
  --admin-identity ${ADMIN_IDENTITY} --cc-name ${CC_NAME} --cc-version ${CC_VERSION} \
  --cc-type ${PLATFORM} --channel ${CHANNEL}"

  if [[ -n $INIT_FN ]]; then
    local INIT_FN_FLAG=" --init-fn ${INIT_FN//\"}"
  fi
  if [[ -n $INIT_ARGS ]]; then
    local INIT_ARGS_FLAG=" --init-args ${INIT_ARGS//\"}"
  fi
  if [[ -n $COLLECTIONS_CONFIG ]]; then
    local COLLECTIONS_CONFIG_FLAG=" --collections-config $(pwd)/${COLLECTIONS_CONFIG}"
  fi

  echo 
  echo ${CMD} ${INIT_FN_FLAG:-""} ${INIT_ARGS_FLAG:-""} ${COLLECTIONS_CONFIG_FLAG:-""} "--timeout 360000"
  echo
  echo ${CMD} ${INIT_FN_FLAG:-""} ${INIT_ARGS_FLAG:-""} ${COLLECTIONS_CONFIG_FLAG:-""} "--timeout 360000" | bash
}


#######################################
# Invoke chaincode function provided specified parameters
# Globals:
#   None
# Arguments:
#   -  $1: ORG: org msp name
#   -  $2: ADMIN_IDENTITY: abs path to associated admin identity
#   -  $3: CONN_PROFILE: abs path to the connection profile
#   -  $4: CC_NAME: chaincode name to be instantiated on the channel
#   -  $5: CC_VERSION: chaincode version to be instantiated on the channel
#   -  $6: CHANNEL: channel name that chaincode will be instantiated on
#   -  $7: PLATFORM: [ golang, node, java ]
#  (-) $8: INVOKE_FN: name of function to invoke
#  (-) $9: INVOKE_ARGS: args passef into the invoke function
# Returns:
#   None
#######################################
function invoke_cc {
  local ORG=$1
  local ADMIN_IDENTITY=$2
  local CONN_PROFILE=$3
  local CC_NAME=$4
  local CC_VERSION=$5
  local CHANNEL=$6
  local PLATFORM=$7
  local INVOKE_FN=${8:-""}
  local INVOKE_ARGS=${9:-""}  

  local CMD="fabric-cli chaincode invoke --conn-profile ${CONN_PROFILE} --org ${ORG} \
  --admin-identity ${ADMIN_IDENTITY} --cc-name ${CC_NAME} --cc-version ${CC_VERSION} \
  --cc-type ${PLATFORM} --channel ${CHANNEL} --invoke-fn ${INVOKE_FN} --invoke-args ${INVOKE_ARGS}"

  echo ${CMD}
  echo
  echo ${CMD} | bash
}