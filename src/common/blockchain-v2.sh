#######################################
# Install chaincode provided specified parameters
# Globals:
#   None
# Arguments:
#   DEPLOY_CONFIG: JSON-formatted string specifying org installing
# chaincode (reference README)
#   PLATFORM: [ "node", "golang", "java" ]
#   SRC_DIR: absolute path to root of chaincode source code
# Returns:
#   None
#######################################
function install_cc {
  local DEPLOY_CONFIG=$1
  local PLATFORM=$2
  local SRC_DIR=$3
  # local ROOTDIR=${4:-"null"} #TEST:

  for org in $(cat ${DEPLOY_CONFIG} | jq 'keys | .[]'); do
    for ccindex in $(cat ${DEPLOY_CONFIG} | jq ".${org}.chaincode |  keys | .[]"); do
      local cc=$(cat ${DEPLOY_CONFIG} | jq ".${org}.chaincode | .[${ccindex}]")      
      for channel in $(echo ${cc} | jq ".channels | .[]"); do
        local conn_profile="${SRC_DIR}/config/${org}-connprofile.json"
        local admin_identity="${SRC_DIR}/config/${org}-admin.json"
        local cc_name=$(cat ${SRC_DIR}/package.json | jq '.name')
        local cc_version=$(cat ${SRC_DIR}/package.json | jq '.version')

        # echo "conn_profile...${conn_profile//\"}"
        # less ${conn_profile//\"}

        echo "fabric-cli chaincode install --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${PLATFORM//\"} --src-dir ${SRC_DIR//\"}"
        echo
        echo
        echo "fabric-cli chaincode install --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${PLATFORM//\"} --src-dir ${SRC_DIR//\"}" | bash
      done
    done
  done
}

#######################################
# Instantiate chaincode on peer(s) provided specified parameters
# Globals:
#   None
# Arguments:
#   - org: org msp name
#   - admin_identity: abs path to associated admin identity
#   - conn_profile: abs path to the connection profile
#   - cc_name: chaincode name to be installed
#   - cc_version: chaincode version to be installed
#   - platform: [ golang, node, java ]
#   - src_dir: absolute path to chaincode directory
# Returns:
#   None
#######################################
function install_cc_standalone {
  local org=$1
  local admin_identity=$2
  local conn_profile=$3
  local cc_name=$4
  local cc_version=$5
  local platform=$6
  local src_dir=$7

  cmd="fabric-cli chaincode install --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${platform//\"} --src-dir ${src_dir//\"}"
  
  echo ${cmd}
  echo
  echo ${cmd} | bash
}

#######################################
# Instantiate chaincode on peer(s) provided specified parameters
# Globals:
#   None
# Arguments:
#   DEPLOY_CONFIG: JSON-formatted string specifying org installing chaincode (reference README)
#   PLATFORM: [ "node", "golang", "java" ]
#   SRC_DIR: absolute path to root of chaincode source code
# Returns:
#   None
#######################################
function instantiate_cc {
  # echo "still in development..."
  local DEPLOY_CONFIG=$1
  local PLATFORM=$2
  local SRC_DIR=$3

  for org in $(cat ${DEPLOY_CONFIG} | jq 'keys | .[]'); do
    for ccindex in $(cat ${DEPLOY_CONFIG} | jq ".${org}.chaincode |  keys | .[]"); do
      local cc=$(cat ${DEPLOY_CONFIG} | jq ".${org}.chaincode | .[${ccindex}]")
      for channel in $(echo ${cc} | jq ".channels | .[]"); do
        # echo ${channel}
        # echo $(echo ${cc} | jq '.init_args')

        # local conn_profile="$org-$channel-connprofile.json"
        local conn_profile="${SRC_DIR}/config/${org}-connprofile.json"
        local admin_identity="${SRC_DIR}/config/$org-admin.json"
        local cc_name=$(cat ${SRC_DIR}/package.json | jq '.name')
        local cc_version=$(cat ${SRC_DIR}/package.json | jq '.version')

        local init_fn=$(echo ${cc} | jq '.init_fn')
        local init_args=$(echo ${cc} | jq '.init_args')
        # echo $init_args

        # TEST: how to format multiple init_args into cli
        if [[ -z $init_args || ${init_args} == "[]" ]]; then
          local cmd="fabric-cli chaincode instantiate --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${PLATFORM//\"} --channel ${channel//\"} --init-function ${init_fn//\"}"
        else
          local cmd="fabric-cli chaincode instantiate --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${PLATFORM//\"} --channel ${channel//\"} --init-function ${init_fn//\"} --init-args ${init_args//\"}"
        fi
        echo ${cmd}; echo; echo

        echo ${cmd} | bash
      done
    done
  done
}

#######################################
# Invoke chaincode function provided specified parameters
# Globals:
#   None
# Arguments:
#   - org: org msp name
#   - admin_identity: abs path to associated admin identity
#   - conn_profile: abs path to the connection profile
#   - cc_name: chaincode name to be instantiated on the channel
#   - cc_version: chaincode version to be instantiated on the channel
#   - channel: channel name that chaincode will be instantiated on
#   - platform: [ golang, node, java ]
#   (-) init_fn: name of function to be instantiated on (default: init)
#   (-) init_args: args passed into the init function (default: [])
# Returns:
#   None
#######################################
function instantiate_cc_standalone {
  local org=$1
  local admin_identity=$2
  local conn_profile=$3
  local cc_name=$4
  local cc_version=$5
  local channel=$6
  local platform=$7
  local init_fn=${8:-"init"}
  local init_args=${9:-"[]"}

  local cmd="fabric-cli chaincode instantiate --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${platform//\"} --channel ${channel//\"} --init-function ${init_fn//\"} --init-args ${init_args//\"}"

  echo ${cmd}
  echo
  echo ${cmd} | bash
}

#######################################
# Invoke chaincode function provided specified parameters
# Globals:
#   None
# Arguments:
#   DEPLOY_CONFIG: JSON-formatted string specifying org installing chaincode (reference README)
#   PLATFORM: [ "node", "golang", "java" ]
#   SRC_DIR: absolute path to root of chaincode source code
# Returns:
#   None
#######################################
function invoke_cc {
  local DEPLOY_CONFIG=$1
  local PLATFORM=$2
  local SRC_DIR=$3

  for org in $(cat ${DEPLOY_CONFIG} | jq 'keys | .[]'); do
    for ccindex in $(cat ${DEPLOY_CONFIG} | jq ".${org}.chaincode |  keys | .[]"); do
      local cc=$(cat ${DEPLOY_CONFIG} | jq ".${org}.chaincode | .[${ccindex}]")
      for channel in $(echo ${cc} | jq ".channels | .[]"); do
        # local conn_profile="$org-$channel-connprofile.json"
        local conn_profile="${SRC_DIR}/config/${org}-connprofile.json"
        local admin_identity="${SRC_DIR}/config/$org-admin.json"
        local cc_name=$(cat ${SRC_DIR}/package.json | jq '.name')
        local cc_version=$(cat ${SRC_DIR}/package.json | jq '.version')

        local invoke_fn=$(echo ${cc} | jq '.init_fn')
        local invoke_args=$(echo ${cc} | jq '.init_args')
        # echo $init_args

        # TEST: how to format multiple init_args into cli
        if [[ -z $invoke_args || ${invoke_args} == "[]" ]]; then
          local cmd="fabric-cli chaincode invoke --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --channel ${channel//\"} --invoke-fn ${invoke_fn//\"} --query true"
        else
          local cmd="fabric-cli chaincode invoke --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${PLATFORM//\"} --channel ${channel//\"} --invoke-fn ${invoke_fn//\"} --invoke-args ${invoke_args//\"} --query true"
        fi

        echo "${cmd}"
        echo
        echo "${cmd}" | bash
      done
    done
  done
}

#######################################
# Invoke chaincode function provided specified parameters
# Globals:
#   None
# Arguments:
#   - org: org msp name
#   - admin_identity: abs path to associated admin identity
#   - conn_profile: abs path to the connection profile
#   - cc_name: chaincode name to be instantiated on the channel
#   - cc_version: chaincode version to be instantiated on the channel
#   - channel: channel name that chaincode will be instantiated on
#   - platform: [ golang, node, java ]
#   (-) init_fn: name of function to be instantiated on (default: init)
#   (-) init_args: args passed into the init function (default: [])
# Returns:
#   None
#######################################
function invoke_cc_standalone {
  local org=$1
  local admin_identity=$2
  local conn_profile=$3
  local cc_name=$4
  local cc_version=$5
  local channel=$6
  local platform=$7
  local invoke_fn=${8:-"queryAllCars"}
  local invoke_args=${9:-"[]"}

  local cmd="fabric-cli chaincode instantiate --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${platform//\"} --channel ${channel//\"} --invoke-fn ${invoke_fn//\"} --invoke-args ${invoke_args//\"}"

  echo ${cmd}
  echo
  echo ${cmd} | bash
}