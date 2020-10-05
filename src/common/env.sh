#!/usr/bin/env bash
ROOTDIR=${ROOTDIR:=$(pwd)}

export DEBUG=${DEBUG:=false}

# set nvm and node expected versions
export NODE_VERSION=${NODE_VERSION:="8.16.2"}
# export NVM_VERSION="0.33.11"
export NVM_VERSION=${NVM_VERSION:="0.35.1"}

# set location for go executables
export GO_VERSION=${GO_VERSION:="1.12"}
export GOROOT=${ROOTDIR}/go
export PATH=${GOROOT}/bin:$PATH
export GOPATH=${ROOTDIR}
export PATH=${GOPATH}/bin:$PATH

# set location for python installation
export PYTHON_VERSION=${PYTHON_VERSION:="2.7.15"}
export PYTHONPATH=/opt/python/${PYTHON_VERSION}

# chaincode dir
export CC_REPO_DIR=${CC_REPO_DIR:-"${ROOTDIR}/chaincode-repo"}
export CONFIGPATH=${CONFIGPATH:-"${CC_REPO_DIR}/deploy_config.json"}
# - only for golang chaincode projects
export CHAINCODEPATH=${CHAINCODEPATH:-"$CC_REPO_DIR/chaincode"}

# hlf dir
export HLF_VERSION=${HLF_VERSION:="1.4.4"}
export FABRIC_SRC_DIR=${ROOTDIR}/fabric-${HLF_VERSION}

# fabric-cli dir
export FABRIC_CLI_DIR=$ROOTDIR/${FABRIC_CLI_DIR:="/fabric-cli"}

## Fabric V2.x Env setup
if [[ $HLF_VERSION = "2."* && $ENABLE_PEER_CLI == 'true' ]];then
    echo "-------- Installing jq --------"
    install_jq

    # Check Required Orderer and Identity file
    if [[ -z $ORDERERS_LIST_JSON_STRING ]];then
        fatalln "ORDERERS_LIST_JSON_STRING not provided!"
    elif [[ -z $ADMIN_IDENTITY_STRING ]];then
        fatalln "ADMIN_IDENTITY_STRING not provided! Please provide json containing cert, key, and cacert"
    elif [[ -z $CONNECTION_PROFILE_STRING ]];then
        fatalln "CONNECTION_PROFILE_STRING not provided! Please provide json containing cert, key, and cacert"
    fi

    if [[ ${ORDERERS_LIST_JSON_STRING::1} != "[" ]]; then
        ORDERERS_LIST_JSON_STRING="["$ORDERERS_LIST_JSON_STRING"]"
    fi

    if [[ ${CONNECTION_PROFILE_STRING::1} != "[" ]]; then
        CONNECTION_PROFILE_STRING="["$CONNECTION_PROFILE_STRING"]"
    fi
    ## Set up list of orderers and tlsCaCert
    orderers=()
    orderer_counter=0
    while read ord_url; do
        orderers+=("${ord_url##*//}") # truncate grpc protocol prefix
        orderer_counter=$(expr $orderer_counter + 1)
    done < <(echo "$ORDERERS_LIST_JSON_STRING" | jq -r '.[] | .api_url')
    export orderers

    echo "$ORDERERS_LIST_JSON_STRING" | jq -r '.[0] | .pem' | base64 -d > ordererpem.pem
    ORDERER_PEM="$(pwd)/ordererpem.pem"

    ## Setup Peer's Identity Env
    ADMIN_IDENTITY_NAME=$(echo ${ADMIN_IDENTITY_STRING} | jq -r '.name')
    ADMIN_IDENTITY_NAME=${ADMIN_IDENTITY_NAME//[[:blank:]]/} #remove spaces

    #Create MSP
    ./${SCRIPT_DIR}/common/create_msp_from_identity.sh "${ADMIN_IDENTITY_STRING}" "${ROOTDIR}/${ADMIN_IDENTITY_NAME}"

    # Download Fabric BIN and setup PEER's core.yaml for identity
    install_fabric_bin
    cp $FABRIC_CFG_PATH/core.yaml "${ROOTDIR}/${ADMIN_IDENTITY_NAME}"

    #Extract env
    #Get Msp
    MSP_ID=$(echo ${CONNECTION_PROFILE_STRING} | jq -r '.[0] | .. | .mspid? | select(.)')
    # Get root tls cert
    echo ${CONNECTION_PROFILE_STRING} | jq -r '.[0] | first(.peers | .. | .pem? | select(.))' > tmpPeerRootCert.pem
    ROOTCACERT=${ROOTDIR}/tmpPeerRootCert.pem

    peers=()
    peers_counter=0
    while read peer_url; do
        peers+=("${peer_url##*//}") # truncate grpc protocol prefix
        peers_counter=$(expr $peers_counter + 1)
    done < <(echo ${CONNECTION_PROFILE_STRING} | jq -r '.[0] | .peers | .. | .url? | select(.)')
    export peers

    # Note: chaincode level shouldn't be array as deploy_config.json is a specific chaincode configuration for distinct source code deployment
    CC_NAME=$(cat $CONFIGPATH | jq -r '. | .. | .chaincode? | .[0] | .name | select(.)')

    json_version=$(cat $CONFIGPATH | jq -r '. | .. | .chaincode? | .[0] | .version? | select(.)')
    if [[ $json_version != null && $json_version != "" ]]; then
        CC_VERSION=$json_version
    else
        CC_VERSION="${CC_VERSION_OVERRIDE:-latest}"
    fi
    #TODO enable multiple channel
    CHANNEL_NAME=$(cat $CONFIGPATH | jq -r '. | .. | .chaincode? | .[0] | .channel | select(.)')

    export CHANNEL_NAME=${CHANNEL_NAME}
    export CC_VERSION=${CC_VERSION}
    export CC_NAME=${CC_NAME}
    export CORE_PEER_LOCALMSPID=${MSP_ID}
    export CORE_PEER_TLS_ROOTCERT_FILE=${ROOTCACERT}
    export CORE_PEER_MSPCONFIGPATH="${ROOTDIR}/${ADMIN_IDENTITY_NAME}/msp"
    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_PEM=${ORDERER_PEM}
    export FABRIC_CFG_PATH="${ROOTDIR}/${ADMIN_IDENTITY_NAME}"
    # Peers and Orderers
    export PEERS_COUNT=${peers_counter}
    export ORDERERS_COUNT=${orderer_counter}
fi