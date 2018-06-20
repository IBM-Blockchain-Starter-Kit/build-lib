#!/bin/bash -x
set -x 
if [ -z "$1" ] 
then
    echo "Invalid input.  Expected dev or prod as script argument"
    exit 1
fi

ENV=$1

export PATH=/opt/IBM/node-v6.7.0/bin:$PATH


# Clone repo with fabric CLI
git clone https://${BX_GIT_PAT}:${BX_GIT_PAT}@git.ng.bluemix.net/${UTILS_REPO_OWNER}/${UTILS_REPO_NAME}.git
# Clone repo with configuration
git clone https://${BX_GIT_PAT}:${BX_GIT_PAT}@git.ng.bluemix.net/${ENV_REPO_OWNER}/${ENV_REPO_NAME}.git

# assumption is that build stage installed go binaries in build directory 
# the second assumption is that the build stage placed the chaincode under 
# the build directory
export GOPATH=$(pwd)/build
export GOROOT=$(pwd)/build/go
export PATH=${GOROOT}/bin:$PATH

# create crypto directory 
export CRYPTO_DIR=${PWD}/crypto
mkdir -p ${CRYPTO_DIR}
cd ${CRYPTO_DIR}
# download tls cert for blockchain services
 wget http://blockchain-certs.mybluemix.net/3.secure.blockchain.ibm.com.rootcert
cd ..

# prepare fabric-cli to run
cd $UTILS_REPO_NAME
npm install


CC_VERSION=$(date +%Y%m%d)-${BUILD_NUMBER}
NET_CONFIG_FILE=${PWD}/../${ENV_REPO_NAME}/config/$ENV/network-config.json
cat $NET_CONFIG_FILE

for org in $( jq -r ".[\"network-config\"]  | keys | to_entries[] | .value " $NET_CONFIG_FILE | grep org | sort -r)
do 
    # setup certs
    certEnvVar=${org}_cert
    keyEnvVar=${org}_key

    mkdir -p $CRYPTO_DIR/${org}/key
    mkdir -p $CRYPTO_DIR/${org}/cert

    if [ -z "${!certEnvVar}" ] 
    then
      echo "Peer Admin cert for org ${org} not specified in env variable. Expecting env variable with named ${org}_cert" 
      exit 1
    fi
    if [ -z "${!keyEnvVar}" ] 
    then
      echo "Peer Admin private key for org ${org} not specified in env variable.  Expecting env variable with named ${org}_key" 
      exit 1
    fi

    echo "${!certEnvVar}" > $CRYPTO_DIR/${org}/cert/cert.pem
    echo "${!keyEnvVar}" > $CRYPTO_DIR/${org}/key/key.priv


    index=0
    jq -r ".[\"network-config\"].$org.chaincode[].path" $NET_CONFIG_FILE | while read cc
    do
        CHANNEL_NAME=$(jq -r ".[\"network-config\"].$org.chaincode[$index].channels[0]" $NET_CONFIG_FILE)
        CC_NAME=$(jq -r ".[\"network-config\"].$org.chaincode[$index].name" $NET_CONFIG_FILE)
        CC_SRC_DIR=$cc

        #Instantiate chaincode
        inst=$(jq -r ".[\"network-config\"].$org.chaincode[$index].install" $NET_CONFIG_FILE)
        if [ "$inst" == "true" ]
        then
            echo "Installing chaincode ${CC_NAME}" 
            node fabric-cli.js chaincode install --net-config $NET_CONFIG_FILE \
            --crypto-dir ${CRYPTO_DIR} --src-dir ${CC_SRC_DIR} --org $org --cc-version ${CC_VERSION} --channel ${CHANNEL_NAME} \
            --cc-name ${CC_NAME}
        fi

        args=""
        OLD_IFS=$IFS
        IFS=" "
        while read arg
        do
            if [ -z "$arg" ]
            then
                continue
            fi
            args="$args --init-arg $arg "
            echo $args
        done <<< $(jq -r ".[\"network-config\"].$org.chaincode[$index].init_args[]" $NET_CONFIG_FILE)
        IFS=$OLD_IFS

        #Instantiate chaincode
        instantiate=$(jq -r ".[\"network-config\"].$org.chaincode[$index].instantiate" $NET_CONFIG_FILE)

        if [ "$instantiate" == "true" ]
        then
            echo "Instantiating chaincode ${CC_NAME} on channel ${CHANNEL_NAME} " 
            node fabric-cli.js chaincode instantiate --net-config $NET_CONFIG_FILE \
            --crypto-dir ${CRYPTO_DIR} --org $org --cc-version ${CC_VERSION} --channel ${CHANNEL_NAME} \
            --cc-name ${CC_NAME} $args

            echo "\n\n******************************************"
            echo "CC_NAME:" ${CC_NAME}
            echo "CC_VERSION:" ${CC_VERSION}
            echo "******************************************\n\n"

            # Verify we can ping the chaincode we just installed 
            node fabric-cli.js chaincode invoke --net-config $NET_CONFIG_FILE \
            --crypto-dir ${CRYPTO_DIR} --org $org --cc-version ${CC_VERSION} --channel ${CHANNEL_NAME} \
            --cc-name ${CC_NAME} --invoke-arg '' --invoke-fn Ping --query
        fi
        index=$(expr $index + 1) 
    done
done
