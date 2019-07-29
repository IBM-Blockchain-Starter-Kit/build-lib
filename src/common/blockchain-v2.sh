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

  for org in $(echo ${DEPLOY_CONFIG} | jq 'keys | .[]'); do
    for ccindex in $(echo ${DEPLOY_CONFIG} | jq ".${org}.chaincode |  keys | .[]"); do
      local cc=$(echo ${DEPLOY_CONFIG} | jq ".${org}.chaincode | .[${ccindex}]")      
      for channel in $(echo ${cc} | jq ".channels | .[]"); do
        local conn_profile="${SRC_DIR}/config/${org}-${channel}-connprofile.json"
        local admin_identity="${SRC_DIR}/config/${org}-admin.json"
        local cc_name=$(echo ${cc} | jq '.cc_name')
        local cc_version=$(echo ${cc} | jq '.cc_version')

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

  for org in $(echo ${DEPLOY_CONFIG} | jq 'keys | .[]'); do
    for ccindex in $(echo ${DEPLOY_CONFIG} | jq ".${org}.chaincode |  keys | .[]"); do
      local cc=$(echo ${DEPLOY_CONFIG} | jq ".${org}.chaincode | .[${ccindex}]")
      for channel in $(echo ${cc} | jq ".channels | .[]"); do
        # echo ${channel}
        # echo $(echo ${cc} | jq '.init_args')

        # local conn_profile="$org-$channel-connprofile.json"
        local conn_profile="${SRC_DIR}/config/${org}-${channel}-connprofile.json"
        local admin_identity="${SRC_DIR}/config/$org-admin.json"
        local cc_name=$(echo ${cc} | jq '.cc_name')
        local cc_version=$(echo ${SRC_DIR} | jq '.cc_version')

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

  for org in $(echo ${DEPLOY_CONFIG} | jq 'keys | .[]'); do
    for ccindex in $(echo ${DEPLOY_CONFIG} | jq ".${org}.chaincode |  keys | .[]"); do
      local cc=$(echo ${DEPLOY_CONFIG} | jq ".${org}.chaincode | .[${ccindex}]")
      for channel in $(echo ${cc} | jq ".channels | .[]"); do
        # local conn_profile="$org-$channel-connprofile.json"
        local conn_profile="${SRC_DIR}/config/${org}-${channel}-connprofile.json"
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

        echo "invoke function..."
        echo ">>> ${cmd}"
        echo
        echo

        echo ${cmd} | bash
      done
    done
  done
}