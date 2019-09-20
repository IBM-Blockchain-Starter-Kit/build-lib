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
function install_fabric_chaincode {
  local ORG=$1
  local ADMIN_IDENTITY=$2
  local CONN_PROFILE=$3
  local CC_NAME=$4
  local CC_VERSION=$5
  local PLATFORM=$6
  local SRC_DIR=$7

  local CMD="fabric-cli chaincode install --conn-profile ${CONN_PROFILE} --org ${ORG} \
  --admin-identity ${ADMIN_IDENTITY} --cc-name ${CC_NAME} --cc-version ${CC_VERSION} \
  --cc-type ${PLATFORM} --src-dir ${SRC_DIR}"

  echo ">>> ${CMD}"
  echo "${CMD}" | bash
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
#  (-)$11: ENDORSEMENT_POLICY: JSON formatted string of endorsement policy
# Returns:
#   None
#######################################
function instantiate_fabric_chaincode {
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
  local ENDORSEMENT_POLICY=${11:-""}

  local INIT_FN_FLAG=""
  local INIT_ARGS_FLAG=""
  local COLLECTIONS_CONFIG_FLAG=""
  local ENDORSEMENT_POLICY_FLAG=""

  local CMD="fabric-cli chaincode instantiate --conn-profile ${CONN_PROFILE} --org ${ORG} \
  --admin-identity ${ADMIN_IDENTITY} --cc-name ${CC_NAME} --cc-version ${CC_VERSION} \
  --cc-type ${PLATFORM} --channel ${CHANNEL}"

  if [[ -n $INIT_FN ]]; then
    INIT_FN_FLAG=" --init-fn ${INIT_FN//\"}"
  fi
  if [[ -n $INIT_ARGS ]]; then
    INIT_ARGS_FLAG=" --init-args ${INIT_ARGS//\"}"
  fi
  if [[ -n $COLLECTIONS_CONFIG ]]; then
    COLLECTIONS_CONFIG_FLAG=" --collections-config $(pwd)/${COLLECTIONS_CONFIG}"
  fi
  if [[ -n $ENDORSEMENT_POLICY ]]; then
    ENDORSEMENT_POLICY_FLAG="  --endorsement-policy '${ENDORSEMENT_POLICY}'"
  fi

  echo ">>> ${CMD} ${INIT_FN_FLAG} ${INIT_ARGS_FLAG} ${COLLECTIONS_CONFIG_FLAG} ${ENDORSEMENT_POLICY_FLAG} --timeout 360000"
  echo "${CMD} ${INIT_FN_FLAG} ${INIT_ARGS_FLAG} ${COLLECTIONS_CONFIG_FLAG} ${ENDORSEMENT_POLICY_FLAG} --timeout 360000" | bash
}