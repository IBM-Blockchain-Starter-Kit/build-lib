#!/usr/bin/env bash

#######################################
# Install chaincode on peer(s) provided specified parameters
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
function install_cc {
  local org=$1
  local admin_identity=$2
  local conn_profile=$3
  local cc_name=$4
  local cc_version=$5
  local platform=$6
  local src_dir=$7

  cmd="fabric-cli chaincode install --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${platform//\"} --src-dir ${src_dir//\"}"

  echo
  echo ${cmd}
  echo
  echo ${cmd} | bash
}


#######################################
# Instantiate chaincode function provided specified parameters
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
function instantiate_cc {
  local org=$1
  local admin_identity=$2
  local conn_profile=$3
  local cc_name=$4
  local cc_version=$5
  local channel=$6
  local platform=$7
  local init_fn=${8:-""}
  local init_args=${9:-""}
  local collections_config=${10:-""}

  local cmd="fabric-cli chaincode instantiate --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${platform//\"} --channel ${channel//\"}"

  if [[ -n $init_fn ]]; then
    local init_fn_flag=" --init-fn ${init_fn//\"}"
  fi
  if [[ -n $init_args ]]; then
    local init_args_flag=" --init-args ${init_args//\"}"
  fi
  if [[ -n $collections_config ]]; then
    local collections_config_flag=" --collections-config $(pwd)/${collections_config}"
  fi

  echo 
  echo ${cmd} ${init_fn_flag:-""} ${init_args_flag:-""} ${collections_config_flag:-""} "--timeout 360000"
  echo
  echo ${cmd} ${init_fn_flag:-""} ${init_args_flag:-""} ${collections_config_flag:-""} "--timeout 360000" | bash
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
#TODO: Properly integrate invoke_cc
function invoke_cc {
  local org=$1
  local admin_identity=$2
  local conn_profile=$3
  local cc_name=$4
  local cc_version=$5
  local channel=$6
  local platform=$7
  local invoke_fn=${8:-"queryAllCars"}
  local invoke_args=${9:-"[]"}

  local cmd="fabric-cli chaincode invoke --conn-profile ${conn_profile//\"} --org ${org//\"} --admin-identity ${admin_identity//\"} --cc-name ${cc_name//\"} --cc-version ${cc_version//\"} --cc-type ${platform//\"} --channel ${channel//\"} --invoke-fn ${invoke_fn//\"} --invoke-args ${invoke_args//\"}"

  echo ${cmd}
  echo
  echo ${cmd} | bash
}

#######################################
# Retrieve api access token
# Globals:
#   None
# Arguments:
#   - apikey: 
# Returns:
#   None
#######################################
function retrieve_access_token {
    local apikey=$1

    if [[ ! -n $(command -v jq) ]]; then
        error_exit "jq interface not found in PATH env variable"
    fi

    curl -X POST \
        https://iam.cloud.ibm.com/identity/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Accept: application/json" \
        --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:apikey" \
        --data-urlencode "apikey=${apikey}" \
    | jq -r ."access_token"
}

#######################################
# 
# Globals:
#   None
# Arguments:
#   - apikey: 
# Returns:
#   None
#######################################
function validate_component {
    local api_endpoint=$1
    # test apikey: mSeo7VrFtt228viF1tWniIFbp4w21NynnXV7rB6eVFZn
    local apikey=${2:-"mSeo7VrFtt228viF1tWniIFbp4w21NynnXV7rB6eVFZn"}
    local component_id=$3

    
    local access_token=$(retrieve_access_token ${apikey}) 
    # echo "access token...${access_token}"   

    # echo $components
    local response=$(curl -X GET "https://${api_endpoint}/ak/api/v1/components" \
        -H "Authorization: Bearer ${access_token}")


    for compindex in $(echo ${response} | jq -r "keys | .[]"); do
        # echo "compindex...$compindex"
        local component=$(echo ${response} | jq -r ".[${compindex}]")
        # for component in $(echo ${response} | jq ".[${compindex}]"); do
        # echo "component...$component"
        # echo $component | jq -r ".id"            
        # continue

        #LOGS:        
        if [[ $(echo $component | jq -r ".msp_id?") != null ]]; then
            local id=$(echo $component | jq -r ".msp_id?")
        else
            local id=$(echo ${component} | jq -r ".id")
        fi

        if [[ $id == $component_id ]]; then
            return 0
        fi
        # done
    done

    error_exit "cannot find requested component: ${component_id}"

    # for compindex in $(echo ${response} | jq -r "keys | .[]"); do
    #     echo $(echo ${response} | jq -r "keys | .[${compindex}]")
    # done
}