#!/usr/bin/env bash

# Common IBM blockchain platform functions, e.g. to provision a blockchain service

# shellcheck disable=2086

# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

function setup_service_constants {
    region_instance=$(echo "$REGION_ID" | cut -d : -f 2)

    if [ "${region_instance}" = "ys1" ]; then
        export BLOCKCHAIN_SERVICE_NAME="ibm-blockchain-5-staging"
        export BLOCKCHAIN_SERVICE_PLAN="ibm-blockchain-plan-v1-ga1-starter-staging"
    else
        export BLOCKCHAIN_SERVICE_NAME="ibm-blockchain-5-prod"
        export BLOCKCHAIN_SERVICE_PLAN="ibm-blockchain-plan-v1-ga1-starter-prod"
    fi

    export BLOCKCHAIN_SERVICE_KEY=Credentials-1
}

function authenticate_org {
    org=$1
    file="blockchain.json"

    BLOCKCHAIN_NETWORK_ID=$(jq --raw-output ".${org}.network_id" ${file})
    BLOCKCHAIN_KEY=$(jq --raw-output ".${org}.key" ${file})
    BLOCKCHAIN_SECRET=$(jq --raw-output ".${org}.secret" ${file})
    BLOCKCHAIN_URL=$(jq --raw-output ".${org}.url" ${file})
}

function provision_blockchain {
    if ! cf service ${BLOCKCHAIN_SERVICE_INSTANCE} > /dev/null 2>&1
    then
        cf create-service ${BLOCKCHAIN_SERVICE_NAME} ${BLOCKCHAIN_SERVICE_PLAN} ${BLOCKCHAIN_SERVICE_INSTANCE}
    fi
    if ! cf service-key ${BLOCKCHAIN_SERVICE_INSTANCE} ${BLOCKCHAIN_SERVICE_KEY} > /dev/null 2>&1
    then
        cf create-service-key ${BLOCKCHAIN_SERVICE_INSTANCE} ${BLOCKCHAIN_SERVICE_KEY}
    fi
    cf service-key ${BLOCKCHAIN_SERVICE_INSTANCE} ${BLOCKCHAIN_SERVICE_KEY} | tail -n +2 > blockchain.json
}

function get_blockchain_connection_profile_inner {
    #set -x
    do_curl \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -u "${BLOCKCHAIN_KEY}:${BLOCKCHAIN_SECRET}" \
        "${BLOCKCHAIN_URL}/api/v1/networks/${BLOCKCHAIN_NETWORK_ID}/connection_profile" > blockchain-connection-profile.json
}

function get_blockchain_connection_profile {
    get_blockchain_connection_profile_inner
    while ! jq -e ".channels.defaultchannel" blockchain-connection-profile.json
    do
        sleep 10
        get_blockchain_connection_profile_inner
    done
}

function install_fabric_chaincode {
    CC_ID=$1
    CC_VERSION=$2
    CC_FILE=$3

    request_url="${BLOCKCHAIN_URL}/api/v1/networks/${BLOCKCHAIN_NETWORK_ID}/chaincode/install"

    echo "Installing fabric contract '$CC_FILE' with id '$CC_ID' and version '$CC_VERSION'..."

    OUTPUT=$(do_curl \
        -X POST \
        -u "${BLOCKCHAIN_KEY}:${BLOCKCHAIN_SECRET}" \
        -F files[]=@"${CC_FILE}" -F chaincode_id="${CC_ID}" -F chaincode_version="${CC_VERSION}" \
        "${request_url}")
    
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

function instantiate_fabric_chaincode {
    CC_ID=$1
    CC_VERSION=$2
    CHANNEL=$3
    INIT_ARGS=$4

    cat << EOF > request.json
{
    "chaincode_id": "${CC_ID}",
    "chaincode_version": "${CC_VERSION}",
    "chaincode_arguments": [${INIT_ARGS}]
}
EOF

    request_url="${BLOCKCHAIN_URL}/api/v1/networks/${BLOCKCHAIN_NETWORK_ID}/channels/${CHANNEL}/chaincode/instantiate"

    echo "Instantiating fabric contract with id '$CC_ID' and version '$CC_VERSION' on channel '$CHANNEL' with arguments '$INIT_ARGS'..."

    OUTPUT=$(
    do_curl \
        -X POST \
        -H 'Content-Type: application/json' \
        -u "${BLOCKCHAIN_KEY}:${BLOCKCHAIN_SECRET}" \
        --data-binary @request.json \
        "${request_url}"
    )
    do_curl_status=$?

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


function parse_fabric_config {
    NET_CONFIG_FILE=$1

    echo "Parsing deployment configuration:"
    cat "$NET_CONFIG_FILE"

    for org in $(jq -r "to_entries[] | .key" "$NET_CONFIG_FILE")
    do
        echo "Targeting org '$org'..."
        authenticate_org "$org"
        
        cc_index=0
        jq -r ".${org}.chaincode[].path" "$NET_CONFIG_FILE" | while read -r CC_PATH
        do
            CC_NAME=$(jq -r ".${org}.chaincode[$cc_index].name" "$NET_CONFIG_FILE")
            CC_FILE="${CC_PATH}/${CC_NAME}.go"
            CC_INSTALL=$(jq -r ".${org}.chaincode[$cc_index].install" "$NET_CONFIG_FILE")
            CC_INSTANTIATE=$(jq -r ".${org}.chaincode[$cc_index].instantiate" "$NET_CONFIG_FILE")
            CC_CHANNELS=$(jq -r ".${org}.chaincode[$cc_index].channels[]" "$NET_CONFIG_FILE")
            CC_INIT_ARGS=$(jq ".${org}.chaincode[$cc_index].init_args[]" "$NET_CONFIG_FILE")

            # TODO: Integrate with configuration
            CC_ID="${CC_NAME}"
            CC_VERSION=$(date '+%Y%m%d%H%M%S')

            if $CC_INSTALL
            then
                install_fabric_chaincode $CC_ID $CC_VERSION $CC_FILE
                
                # If install failed due to a reason other than an identical version already exists, skip instantiate
                if [ $? -eq 1 ]; then
                    continue
                fi
            fi

            if $CC_INSTANTIATE
            then
                for channel in $CC_CHANNELS
                do
                    instantiate_fabric_chaincode $CC_ID $CC_VERSION $channel $CC_INIT_ARGS
                done  
            fi
            cc_index=$((cc_index + 1))
        done
    done

    echo "Done parsing deployment configuration."
}
