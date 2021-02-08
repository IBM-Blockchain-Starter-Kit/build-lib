

source "${SCRIPT_DIR}/common/utils.sh"

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
    COLLECTIONS_CONFIG_FLAG=" --collections-config ${COLLECTIONS_CONFIG}"
  fi

  if [[ -n $ENDORSEMENT_POLICY ]]; then
    ENDORSEMENT_POLICY_FLAG="  --endorsement-policy '${ENDORSEMENT_POLICY}'"
  fi

  echo ">>> ${CMD} ${INIT_FN_FLAG} ${INIT_ARGS_FLAG} ${COLLECTIONS_CONFIG_FLAG} ${ENDORSEMENT_POLICY_FLAG} --timeout 360000"
  echo "${CMD} ${INIT_FN_FLAG} ${INIT_ARGS_FLAG} ${COLLECTIONS_CONFIG_FLAG} ${ENDORSEMENT_POLICY_FLAG} --timeout 360000" | bash
}

##### THIS SECTION BELOW ARE FOR FABRIC V2.X CLI CMDS

#######################################
# V2.x Install chaincode on peer(s) provided specified parameters
# Requires peer cli env and msp to be set
# Globals:
#   CORE_PEER_ADDRESS: peer address to install
# Arguments:
#   - $1: CC_PACKAGE: Package of CC
# Returns:
#   None
#######################################
installChaincode_v2() {
    #TODO add flag to avoid installing all peers
    ## Note that there is a better way instead of looping through all of the peers: fix https://jira.hyperledger.org/browse/FAB-18339?filter=-2
    cc_package=$1
    for peer in "${!peersMap[@]}";do
        export CORE_PEER_ADDRESS=${peer}
        export CORE_PEER_TLS_ROOTCERT_FILE=${peersMap[$peer]}
        if [[ "${PEER_CLI_V1}" == "true" ]];then
          peer chaincode install ${cc_package}
        else
          peer lifecycle chaincode install ${cc_package}
        fi
        res=$?
        verifyResult $res "Chaincode ${cc_package} installation on ${CORE_PEER_ADDRESS} "
    done
}


#######################################
# V1.x Upgrades the chiancode if the chaincode is instantiated
#TODO
# Globals:
#   CORE_PEER_ADDRESS: peer address to install
# Arguments:
#   - $1: CC_PACKAGE: Package of CC
# Returns:
#   None
#######################################
instantiate_peer_cli() {

  for ord in ${orderers[@]};do
    ## Check for instantiated, if instantiated, only upgrade
    if [[ `peer chaincode list --instantiated -C $CHANNEL_NAME` == *${CC_NAME}* ]];then
      echo "instnatiated"
      peer chaincode upgrade -o ${ord} --tls --cafile "${ORDERER_PEM}" \
        --channelID $CHANNEL_NAME \
        --name ${CC_NAME}  \
        --version ${CC_VERSION} \
        ${CC_PDC_CONFIG} ${CC_ENDORSEMENT_OPTION} ${ENDORSEMENT_POLICY} ${CC_INIT_ARGS_OPTION} "${INIT_ARGS}"
        res=$?
    else
      peer chaincode instantiate -o ${ord} --tls --cafile "${ORDERER_PEM}" \
        --channelID $CHANNEL_NAME \
        --name ${CC_NAME}  \
        --version ${CC_VERSION} \
        ${CC_PDC_CONFIG} ${CC_ENDORSEMENT_OPTION} ${ENDORSEMENT_POLICY} ${CC_INIT_ARGS_OPTION} "${INIT_ARGS}"
        res=$?
    fi

    verifyResult $res "Chaincode definition instantiation on ${CORE_PEER_ADDRESS} on channel '$CHANNEL_NAME'"
    if [[ $res == 0 ]];then
        break
    fi

  done
}

#######################################
# V2.x Query Installed chaincode on peer(s) provided specified parameters
# Requires peer cli env and msp to be set
# Globals:
#   CORE_PEER_ADDRESS: peer address to install
#   CC_NAME: chaincode name
#   CC_VERSION: chaincode version
# Arguments:
#   None
# Returns:
#   Set PACKAGE_ID env for lifecycle approveformyorg
#######################################
queryInstalled() {

    peer lifecycle chaincode queryinstalled >&log.txt
    res=$?
    cat log.txt
    PACKAGE_ID=$(cat log.txt | awk "/$CC_NAME/ && /$CC_VERSION/" | awk '{print $3}')
    PACKAGE_ID=${PACKAGE_ID%%,*}
    export PACKAGE_ID=${PACKAGE_ID}

    if [[ ${PACKAGE_ID} == "" ]];then
        res=3
    fi

    verifyResult $res "Query installed on ${CORE_PEER_ADDRESS} with Package ID : ${PACKAGE_ID} "

}

#######################################
# V2.x checkCommitReadiness VERSION PEER ORG
# Requires peer cli env and msp to be set
# Globals:
#   CORE_PEER_ADDRESS: peer address to install
#   CC_NAME: chaincode name
#   CC_VERSION: chaincode version
#   CHANNEL_NAME: channel name to check commit readiness
#   MAX_RETRY: max retry count
#   DELAY: Delay count for retry
#   CC_SEQUENCE: sequence number for chaincode lifecycle - defaults to 1 if not set
# Arguments:
#   None
# Returns:
#   None
#######################################
checkCommitReadiness() {

    infoln "Checking the commit readiness of the chaincode definition on ${CORE_PEER_ADDRESS} on channel '$CHANNEL_NAME'..."
    local rc=1
    local COUNTER=1

    infoln "Attempting to check the commit readiness of the chaincode definition on ${CORE_PEER_ADDRESS}, Retry after $DELAY seconds."
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --sequence ${CC_SEQUENCE} \
        --output json ${CC_PDC_CONFIG} ${CC_SIGNATURE_OPTION} ${SIGN_POLICY} >&log.txt
    res=$?
    cat log.txt
    status=$(cat log.txt | jq -rc '.approvals')
    if [[ $status =~ "true" ]];then
        rc=0
    fi


    if test $rc -eq 0; then
        infoln "Checking the commit readiness of the chaincode definition successful on ${CORE_PEER_ADDRESS} on channel '$CHANNEL_NAME'"
    else
        fatalln "After $COUNTER attempts, Check commit readiness result on ${CORE_PEER_ADDRESS} is INVALID!"
    fi

}

#######################################
# V2.x commitChaincodeDefinition VERSION PEER ORG (PEER ORG)... on all peers
# Requires peer cli env and msp to be set
# Globals:
#   CORE_PEER_ADDRESS: peer address to install
#   CC_NAME: chaincode name
#   CC_VERSION: chaincode version
#   CHANNEL_NAME: channel name to check commit readiness
#   MAX_RETRY: max retry count
#   DELAY: Delay count for retry
#   CC_SEQUENCE: sequence number for chaincode lifecycle - defaults to 1 if not set
# Arguments:
#   None
# Returns:
#   Set PACKAGE_ID env for lifecycle approveformyorg
#######################################
commitChaincodeDefinition() {

    for ord in ${orderers[@]};do

        peer lifecycle chaincode commit -o ${ord} --tls --cafile "${ORDERER_PEM}" \
        --channelID $CHANNEL_NAME \
        --name ${CC_NAME}  \
        --version ${CC_VERSION} \
        ${PEER_ADDRESSES_STRING} \
        --sequence ${CC_SEQUENCE}  \
        --waitForEvent ${CC_PDC_CONFIG} ${CC_SIGNATURE_OPTION} ${SIGN_POLICY}
        res=$?

        verifyResult $res "Chaincode definition commit on ${CORE_PEER_ADDRESS} on channel '$CHANNEL_NAME'"
        if [[ $res == 0 ]];then
            break
        fi

    done
}

#######################################
# V2.x Query commited chaincode for org with retry
# Requires peer cli env and msp to be set
# Globals:
#   CORE_PEER_ADDRESS: peer address to install
#   CC_NAME: chaincode name
#   CC_VERSION: chaincode version
#   CHANNEL_NAME: channel name to check commit readiness
#   MAX_RETRY: max retry count
#   DELAY: Delay count for retry
#   CC_SEQUENCE: sequence number for chaincode lifecycle - defaults to 1 if not set
# Arguments:
#   None
# Returns:
#   Set PACKAGE_ID env for lifecycle approveformyorg
#######################################
queryCommitted() {

    infoln "Querying chaincode definition on ${CORE_PEER_ADDRESS} on channel '$CHANNEL_NAME'..."
    local rc=1
    local COUNTER=1

    infoln "Attempting to Query committed ${CC_NAME} status on ${CORE_PEER_ADDRESS}"
    set +e
    peer lifecycle chaincode querycommitted --output json --channelID $CHANNEL_NAME --name ${CC_NAME} > log.txt 2>&1
    set -e
    res=${PIPESTATUS[0]}
    echo "res=$res"
#        cat log.txt
    if [[ $res -eq 0 ]];then
        #TODO need to accouont for multiple peer that may not have their commited seq in sync
        export LATEST_SEQ=$(jq -r '.sequence' log.txt)
    fi
    OK_STATUS="Error: query failed with status: 404 - namespace ${CC_NAME} is not defined"

    if [[ $OK_STATUS != $(cat log.txt) ]];then
        verifyResult $res "$(cat log.txt)"
    else
        verifyResult 0 "$(cat log.txt)"
    fi

}

#######################################
# V2.x Package chaincode for lifecycle
# Requires peer cli env and msp to be set
# Globals:
#    CC_PATH: Abs path to cc
#    CC_NAME: chaincode name
#    CC_VERSION: chaincode version
#    LANG: chaincode runtime
# Arguments:
#   None
# Returns:
#   None
#######################################
packageCC() {
    set -x
    local CC_PATH=$1
    local CC_NAME=$2
    local CC_VERSION=$3
    local CC_SEQUENCE=$4
    local LANG=$5
    verifyPeerEnv

    if [[ $HLF_VERSION == "1."* ]];then
      LABEL=${CC_NAME}-${CC_VERSION}
      peer chaincode package \
        --lang "${LANG}" \
        --name "${CC_NAME}" \
        --version "${CC_VERSION}" \
        --path "${CC_PATH}" "${CC_NAME}@${CC_VERSION}.tgz"
      res=$?
    else
      LABEL=${CC_NAME}-${CC_VERSION}-${CC_SEQUENCE}
      peer lifecycle chaincode package ${CC_NAME}@${CC_VERSION}.tgz \
          --lang ${LANG} \
          --label ${LABEL} \
          --path ${CC_PATH}
      res=$?
    fi

    verifyResult $res "Chaincode package for ${LABEL} "
}

#######################################
# V2.x Package chaincode for lifecycle
# Requires peer cli env and msp to be set
# Globals:
#    CC_PATH: Abs path to cc
#    CC_NAME: chaincode name
#    CC_VERSION: chaincode version
#    LANG: chaincode runtime
# Arguments:
#   None
# Returns:
#   None
#######################################
approveForMyOrg() {

    for ord in ${orderers[@]};do

        peer lifecycle chaincode approveformyorg -o ${ord} --tls --cafile "${ORDERER_PEM}" \
        --channelID $CHANNEL_NAME \
        --name ${CC_NAME} \
        --version ${CC_VERSION} \
        --sequence ${CC_SEQUENCE} \
        --package-id ${PACKAGE_ID} \
        --waitForEvent ${CC_PDC_CONFIG} ${CC_SIGNATURE_OPTION} ${SIGN_POLICY}
        res=$?

        verifyResult $res "Chaincode definition ${PACKAGE_ID} approved on ${CORE_PEER_ADDRESS} on channel '$CHANNEL_NAME' "

        # Approval only required for 1 peer so break if successful, this is default : TODO enable some logic that requires some policy?
        if [[ $res == 0 ]];then
            break
        fi

    done
}