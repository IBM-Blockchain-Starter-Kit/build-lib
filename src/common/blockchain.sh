#!/usr/bin/env bash

# Common IBM blockchain platform functions, e.g. to provision a blockchain service

# shellcheck disable=2086
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

#######################################
# Setup constants for bluemix cloud foundry interaction
# Globals:
#   get: REGION_ID
#   set: BLOCKCHAIN_SERVICE_NAME
#   set: BLOCKCHAIN_SERVICE_PLAN
#   set: BLOCKCHAIN_SERVICE_KEY
# Arguments:
#   None
# Returns:
#   None
#######################################
function setup_service_constants {
    local region_instance

    region_instance=$(echo "$REGION_ID" | cut -d : -f 2)

    if [ "${region_instance}" = "ys1" ]; then
        BLOCKCHAIN_SERVICE_NAME="ibm-blockchain-5-staging"
        BLOCKCHAIN_SERVICE_PLAN="ibm-blockchain-plan-v1-ga1-starter-staging"
    else
        BLOCKCHAIN_SERVICE_NAME="ibm-blockchain-5-prod"
        BLOCKCHAIN_SERVICE_PLAN="ibm-blockchain-plan-v1-ga1-starter-prod"
    fi

    export BLOCKCHAIN_SERVICE_KEY="Credentials-1"
    export BLOCKCHAIN_SERVICE_NAME
    export BLOCKCHAIN_SERVICE_PLAN
}

#######################################
# Update network credentials to reflect targeted 'org' argument using 'blockchain.json'
# Globals:
#   set: BLOCKCHAIN_SECRET
#   set: BLOCKCHAIN_KEY
#   set: BLOCKCHAIN_API
# Arguments:
#   org: must match a top-level key in 'blockchain.json'
# Returns:
#   None
#######################################
function authenticate_org {
    local org=$1
    local file="blockchain.json"

    local BLOCKCHAIN_NETWORK_ID
    local BLOCKCHAIN_URL

    BLOCKCHAIN_NETWORK_ID=$(jq --raw-output ".${org}.network_id" ${file})
    BLOCKCHAIN_URL=$(jq --raw-output ".${org}.url" ${file})
    BLOCKCHAIN_KEY=$(jq --raw-output ".${org}.key" ${file})
    BLOCKCHAIN_SECRET=$(jq --raw-output ".${org}.secret" ${file})

    BLOCKCHAIN_API="${BLOCKCHAIN_URL}/api/v1/networks/${BLOCKCHAIN_NETWORK_ID}"
}

#######################################
# Populate 'blockchain.json' with network credentials by interacting with the 
# bluemix cloud foundry CLI to create/modify service instance and key
# Globals:
#   get: BLOCKCHAIN_SERVICE_INSTANCE
#   get: BLOCKCHAIN_SERVICE_NAME
#   get: BLOCKCHAIN_SERVICE_PLAN
#   get: BLOCKCHAIN_SERVICE_KEY
# Arguments:
#   None
# Returns:
#   None
#######################################
function provision_blockchain {
    SERVICE_OUTPUT=$(cf service ${BLOCKCHAIN_SERVICE_INSTANCE})
    RETVAL=$?

    if [ $RETVAL -eq 0 ] && [[ ${SERVICE_OUTPUT} != *"Service: ${BLOCKCHAIN_SERVICE_NAME}"* ]]
    then
        echo "Service with the provided name exists, but it is not a blockchain service."
        exit 1
    fi

    if [ $RETVAL -eq 1 ]
    then
        cf create-service ${BLOCKCHAIN_SERVICE_NAME} ${BLOCKCHAIN_SERVICE_PLAN} ${BLOCKCHAIN_SERVICE_INSTANCE}
        if [ $? -eq 1 ]; then
            echo "Failed to create service."
            exit 1
        fi
    fi
    cf service-key ${BLOCKCHAIN_SERVICE_INSTANCE} ${BLOCKCHAIN_SERVICE_KEY}
    if [ $? -eq 1 ]
    then
        cf create-service-key ${BLOCKCHAIN_SERVICE_INSTANCE} ${BLOCKCHAIN_SERVICE_KEY}
        if [ $? -eq 1 ]; then
            echo "Failed to create service key."
            exit 1
        fi
    fi
    cf service-key ${BLOCKCHAIN_SERVICE_INSTANCE} ${BLOCKCHAIN_SERVICE_KEY} | tail -n +2 > blockchain.json
}

#######################################
# Helper for get_blockchain_connection_profile
# Globals:
#   get: BLOCKCHAIN_KEY
#   get: BLOCKCHAIN_SECRET
#   get: BLOCKCHAIN_API
# Arguments:
#   None
# Returns:
#   None
#######################################
function get_blockchain_connection_profile_inner {
    do_curl \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -u "${BLOCKCHAIN_KEY}:${BLOCKCHAIN_SECRET}" \
        "${BLOCKCHAIN_API}/connection_profile" > blockchain-connection-profile.json
}

#######################################
# Requests and waits for network information from the IBM Blockchain platform 
# api, outputting into 'blockchain-connection-profile.json'
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function get_blockchain_connection_profile {
    get_blockchain_connection_profile_inner
    while ! jq -e ".channels.defaultchannel" blockchain-connection-profile.json
    do
        sleep 10
        get_blockchain_connection_profile_inner
    done
}

#######################################
# Installs chaincode file with specified id and version
# Globals:
#   get: BLOCKCHAIN_API
#   get: BLOCKCHAIN_KEY
#   get: BLOCKCHAIN_SECRET
# Arguments:
#   CC_ID:      Name to label installation with
#   CC_VERSION: Version to label installation with
#   CC_PATH:    Path to chaincode directory to be installed
#   CC_TYPE:    Type of chaincode to install (golang|node)
# Returns:
#   err_no:
#     2 = chaincode exists with specified id and version
#     1 = unrecognized error returned by IBM Blockchain platform api
#     0 = chaincode successfully installed with specified id and version
#######################################
function install_fabric_chaincode {
    local CC_ID=$1
    local CC_VERSION=$2
    local CC_PATH=$3
    local CC_TYPE=$4

    local CHAINCODE_FILES

    echo "Installing chaincode '$CC_PATH' with id '$CC_ID' and version '$CC_VERSION'..."
    
    CHAINCODE_FILES=$(find ${CC_PATH} -type f ! -name "*test*")
    CHAINCODE_FILE_OPTS=""
    for CHAINCODE_FILE in ${CHAINCODE_FILES}
    do
        CHAINCODE_FILE_OPTS="${CHAINCODE_FILE_OPTS} -F files[]=@${CHAINCODE_FILE}"
    done

    OUTPUT=$(do_curl \
        -X POST \
        -u "${BLOCKCHAIN_KEY}:${BLOCKCHAIN_SECRET}" \
        $CHAINCODE_FILE_OPTS \
        -F chaincode_id="${CC_ID}" -F chaincode_version="${CC_VERSION}" \
        -F chaincode_type="${CC_TYPE}" \
        "${BLOCKCHAIN_API}/chaincode/install")
    
    if [ $? -eq 1 ]
    then
        echo "Failed to install fabric contract:"
        if [[ "${OUTPUT}" == *"chaincode code"*"exists"* ]]
        then
            echo "Chaincode already installed with id '${CC_ID}' and version '${CC_VERSION}'"
            return 2
        else
            echo "Unrecognized error returned:"
            echo "$OUTPUT"
            return 1
        fi  
    fi

    echo "Successfully installed fabric contract."
    return 0
}

#######################################
# Instantiates chaincode object with specified id and version in target channel, 
# using optional initial arguments
# Globals:
#   get: BLOCKCHAIN_API
#   get: BLOCKCHAIN_KEY
#   get: BLOCKCHAIN_SECRET
# Arguments:
#   CC_ID:      Name to label instance with
#   CC_VERSION: Version to label instance with
#   CC_TYPE:    Type of chaincode to instantiate (golang|node)
#   CHANNEL:    Channel for instance to be constructed in
#   INIT_ARGS:  (optional) Constructor arguments
# Returns:
#   err_no:
#     2 = chaincode instance exists with specified id and version
#     1 = unrecognized error returned by IBM Blockchain platform api
#     0 = chaincode successfully instantiated with specified id and version
#######################################
function instantiate_fabric_chaincode {
    local CC_ID=$1
    local CC_VERSION=$2
    local CC_TYPE=$3
    local CHANNEL=$4
    local INIT_ARGS=$5

    cat << EOF > request.json
{
    "chaincode_id": "${CC_ID}",
    "chaincode_version": "${CC_VERSION}",
    "chaincode_type": "${CC_TYPE}",
    "chaincode_arguments": [${INIT_ARGS}]
}
EOF

    echo "Instantiating fabric contract with id '$CC_ID' and version '$CC_VERSION' on channel '$CHANNEL' with arguments '$INIT_ARGS'..."
    
    echo "request.json content:"
    cat request.json

    OUTPUT=$(do_curl \
        -X POST \
        -H 'Content-Type: application/json' \
        -u "${BLOCKCHAIN_KEY}:${BLOCKCHAIN_SECRET}" \
        --data-binary @request.json \
        "${BLOCKCHAIN_API}/channels/${CHANNEL}/chaincode/instantiate")
    
    local do_curl_status=$?

    rm -f request.json

    if [[ "${OUTPUT}" == *"Failed to establish a backside connection"* || "${OUTPUT}" == *"premature execution"* ]]
    then
        echo "Connection problem encountered, delaying 30s and trying again..."
        sleep 30
        instantiate_fabric_chaincode "$@"
        return $?
    fi

    if [ $do_curl_status -eq 1 ]
    then
        echo "Failed to instantiate fabric contract:"
        if [[ "${OUTPUT}" == *"version already exists for chaincode"* ]]
        then
            echo "Chaincode instance already exists with id '${CC_ID}' and version '${CC_VERSION}'"
            return 2
        else
            echo "Unrecognized error returned:"
            echo "${OUTPUT}"
            return 1
        fi
    fi

    echo "Successfully instantiated fabric contract."
    return 0
}

#######################################
# Parses deployment configuration and makes corresponding install and 
# instatiate requests
# Globals:
#   None
# Arguments:
#   CC_TYPE:       Type of chaincode to deploy (golang|node)
#   DEPLOY_CONFIG: path to json config file
# Returns:
#   None
#######################################
function deploy_fabric_chaincode {
    local CC_TYPE=$1
    local DEPLOY_CONFIG=$2

    echo "Parsing deployment configuration:"
    cat "$DEPLOY_CONFIG"

    for org in $(jq -r "to_entries[] | .key" "$DEPLOY_CONFIG")
    do
        echo "Targeting org '$org'..."
        authenticate_org "$org"
        
        local cc_index=0
        jq -r ".${org}.chaincode[].path" "$DEPLOY_CONFIG" | while read -r CC_PATH
        do
            CC_NAME=$(jq -r ".${org}.chaincode[$cc_index].name" "$DEPLOY_CONFIG")
            CC_INSTALL=$(jq -r ".${org}.chaincode[$cc_index].install" "$DEPLOY_CONFIG")
            CC_INSTANTIATE=$(jq -r ".${org}.chaincode[$cc_index].instantiate" "$DEPLOY_CONFIG")
            CC_CHANNELS=$(jq -r ".${org}.chaincode[$cc_index].channels[]" "$DEPLOY_CONFIG")
            CC_INIT_ARGS=$(jq ".${org}.chaincode[$cc_index].init_args[]" "$DEPLOY_CONFIG")

            # TODO: Integrate with configuration
            CC_ID="${CC_NAME}"
            CC_VERSION="$(date '+%Y%m%d%H%M%S')-${BUILD_NUMBER}"

            if $CC_INSTALL
            then
                install_fabric_chaincode $CC_ID $CC_VERSION $CC_PATH $CC_TYPE
                
                # If install failed due to a reason other than an identical version already exists, skip instantiate
                if [ $? -eq 1 ]; then
                    continue
                fi
            fi

            if $CC_INSTANTIATE
            then
                for channel in $CC_CHANNELS
                do
                    instantiate_fabric_chaincode $CC_ID $CC_VERSION $CC_TYPE $channel $CC_INIT_ARGS
                done  
            fi
            cc_index=$((cc_index + 1))
        done
    done

    echo "Done parsing deployment configuration."
}
