
ROOTDIR=${ROOTDIR:=$(pwd)}

export DEBUG=${DEBUG:=false}

# set nvm and node expected versions
export NODE_VERSION=${NODE_VERSION:="8.16.2"}
# export NVM_VERSION="0.33.11"
export NVM_VERSION=${NVM_VERSION:="0.35.1"}

# set location for go executables
export GO_VERSION=${GO_VERSION:="1.12"}
export GOROOT=${GOROOT:-"${ROOTDIR}/go"}
export PATH=${GOROOT}/bin:$PATH
export GOPATH=${GOPATH:-"${ROOTDIR}/go"}
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
export HLF_VERSION=${HLF_VERSION:="1.4.9"}
export FABRIC_SRC_DIR=${ROOTDIR}/fabric-${HLF_VERSION}

# fabric-cli dir
export FABRIC_CLI_DIR=$ROOTDIR/${FABRIC_CLI_DIR:="/fabric-cli"}

## Fabric V2.x Env setup
if [[ $HLF_VERSION == "1."* && $ENABLE_PEER_CLI == 'true' ]] || [[ $HLF_VERSION == "2."* && $ENABLE_PEER_CLI == 'true' ]];then
    if [[ $DEBUG == 'true' ]];then set -x; fi;
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
    cert=$(echo "${ADMIN_IDENTITY_STRING}" | jq -r '.cert')
    ca=$(echo "${ADMIN_IDENTITY_STRING}" | jq -r '.ca')
    key=$(echo "${ADMIN_IDENTITY_STRING}" | jq -r '.private_key')
    name=$(echo "${ADMIN_IDENTITY_STRING}" | jq -r '.name')

    source ${SCRIPT_DIR}/common/create_msp_from_identity.sh "${ROOTDIR}/${ADMIN_IDENTITY_NAME}" "${cert}" "${ca}" "${key}" "${name}"
#    ./${SCRIPT_DIR}/common/create_msp_from_identity.sh "${ROOTDIR}/${ADMIN_IDENTITY_NAME}" "${cert}" "${key}" "${name}"

    # Download Fabric BIN and setup PEER's core.yaml for identity
    install_fabric_bin "${HLF_VERSION}" "1.4.9" # ca 1.4.9 is latest
    ## Check if dir exists
    [[ ! -d "${ROOTDIR}/${ADMIN_IDENTITY_NAME}" ]] && exit 6

    cp $(pwd)/config/core.yaml "${ROOTDIR}/${ADMIN_IDENTITY_NAME}/"

    #Extract env
    #Get Msp
    MSP_ID=$(echo ${CONNECTION_PROFILE_STRING} | jq -r '.[0] | .. | .mspid? | select(.)')
    # Get root tls cert for first peer
    echo ${CONNECTION_PROFILE_STRING} | jq -r '.[0] | first(.peers | .. | .pem? | select(.))' > tmpPeerRootCert.pem
    ROOTCACERT=${ROOTDIR}/tmpPeerRootCert.pem
    # Get first peer url
    PEER_ADDR=$(echo ${CONNECTION_PROFILE_STRING} | jq -r '.[0] | first(.peers | .. | .url? | select(.))')
    # peers array deprecated TODO
    peers=()
    peers_counter=0
    while read peer_url; do
        peers+=("${peer_url##*//}") # truncate grpc protocol prefix
        peers_counter=$(expr $peers_counter + 1)
    done < <(echo ${CONNECTION_PROFILE_STRING} | jq -r '.[0] | .peers | .. | .url? | select(.)')
    export peers
    #peers array above should be removed
    declare -A peersMap
    while read -r peerObj; do
    #    echo $peerObj
        peerUrl=$(echo $peerObj | jq -r '.url')
        peerUrl=${peerUrl##*//}
        peerPemFile=${peerUrl}.pem
        #save pemfile
        echo $peerObj | jq -r '.pem' > ${peerPemFile}
        # create map
        peersMap["${peerUrl}"]=$(pwd)/${peerPemFile}
    done < <(echo "${CONNECTION_PROFILE_STRING}" | jq -rc '.[0] | .peers | keys[] as $k | {"url": "\(.[$k] | .url)" , "pem": "\(.[$k] | .tlsCACerts.pem)"}')
    export peersMap

    ## Build the peer string for peer cli
    peerAddrString=""
    for peer in "${!peersMap[@]}";do
        peerAddrString+="--peerAddresses $peer --tlsRootCertFiles ${peersMap[$peer]} "
    done

    # Note: chaincode level shouldn't be array as deploy_config.json is a specific chaincode configuration for distinct source code deployment
    # TODO Allow CC_NAME override at pipeline
    if [[ -z "${CC_INDEX}" ]];then
        #set default
        CC_INDEX=0
    fi
    if [[ ! -z "${CC_NAME_OVERRIDE}" ]];then
        CC_NAME=${CC_NAME_OVERRIDE}
    else
        CC_NAME=$(cat $CONFIGPATH | jq -r --argjson cc_index $CC_INDEX '. | .. | .chaincode? | .[$cc_index] | .name | select(.)')
    fi

    json_version=$(cat $CONFIGPATH | jq -r --argjson cc_index $CC_INDEX  '. | .. | .chaincode? | .[$cc_index] | .version? | select(.)')
    if [[ $json_version != null && $json_version != "" ]]; then
        CC_VERSION=$json_version
    else
        CC_VERSION="${CC_VERSION_OVERRIDE:-latest}"
    fi
    #TODO enable multiple channel
    CHANNEL_NAME=$(cat $CONFIGPATH | jq -r --argjson cc_index $CC_INDEX  '. | .. | .chaincode? | .[$cc_index] | .channel | select(.)')

    ##PDC
    pdc_json_path=$(cat $CONFIGPATH | jq -r --argjson cc_index $CC_INDEX  '. | .. | .chaincode? | .[$cc_index] | .pdc_path? | select(.)')

    if [[ $pdc_json_path != null && $pdc_json_path != "" ]]; then
        CC_PDC_CONFIG="--collections-config ${CC_REPO_DIR}/${pdc_json_path}"
    else
        CC_PDC_CONFIG=""
    fi

    ## Signature policy should be defined at cicd by admin
    if [[ -z $SIGN_POLICY ]];then
        SIGN_POLICY=""
        export CC_SIGNATURE_OPTION=""
    else
        export CC_SIGNATURE_OPTION=--signature-policy
    fi

    ## Endorsement policy should be defined at cicd by admin
    if [[ -z $ENDORSEMENT_POLICY ]];then
        ENDORSEMENT_POLICY=""
        export CC_ENDORSEMENT_OPTION=""
    else
        export CC_ENDORSEMENT_OPTION=--policy
    fi

    ## Init Constructor if needed
    if [[ -z $INIT_ARGS ]];then
        INIT_ARGS=""
        export CC_INIT_ARGS_OPTION=""
    else
        export CC_INIT_ARGS_OPTION=--ctor
    fi

    export CC_PDC_CONFIG=${CC_PDC_CONFIG}
    export CHANNEL_NAME=${CHANNEL_NAME}
    export CC_VERSION=${CC_VERSION}
    export CC_NAME=${CC_NAME}
    export CORE_PEER_ADDRESS=${PEER_ADDR##*//}
    export CORE_PEER_LOCALMSPID=${MSP_ID}
    export CORE_PEER_TLS_ROOTCERT_FILE=${ROOTCACERT}
    export CORE_PEER_MSPCONFIGPATH="${ROOTDIR}/${ADMIN_IDENTITY_NAME}/msp"
    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_PEM=${ORDERER_PEM}
    export FABRIC_CFG_PATH="${ROOTDIR}/${ADMIN_IDENTITY_NAME}"
    # Peers and Orderers counts from gateways
    export PEERS_COUNT=${peers_counter}
    export PEER_ADDRESSES_STRING=${peerAddrString} ##Not being used so safe for fab v1.x
    export ORDERERS_COUNT=${orderer_counter}
fi
