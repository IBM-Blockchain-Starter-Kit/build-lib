#!/usr/bin/env bash

set -ex

export COMPOSER_VERSION=0.20.3

function install_nodejs {
    npm config delete prefix
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 8
    nvm use 8
    node -v
    npm -v
}

function install_composer {
    npm install -g composer-cli@${COMPOSER_VERSION} composer-wallet-cloudant
}

function install_jq {
    curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
    chmod +x jq
    export PATH=${PATH}:${PWD}
}

function do_curl {
    HTTP_RESPONSE=$(mktemp)
    HTTP_STATUS=$(curl -w '%{http_code}' -o ${HTTP_RESPONSE} "$@")
    cat ${HTTP_RESPONSE}
    rm -f ${HTTP_RESPONSE}
    if [[ ${HTTP_STATUS} -ge 200 && ${HTTP_STATUS} -lt 300 ]]
    then
        return 0
    else
        return ${HTTP_STATUS}
    fi
}

# Creates a name that is likely to be unique, which is suitable for use
# when deploying apps to bluemix
#   get_deploy_name <uuid> [<name> ...]
function get_deploy_name {
    uuid="${1:?get_deploy_name must be called with at least one argument}"
    shift

    old_ifs="$IFS"
    IFS='_'
    name="$*"
    IFS=$old_ifs

    unique_name="${name}_${uuid}"

    short_hash=$(echo "${unique_name}" | git hash-object --stdin | head -c 7)

    deploy_name=$(echo "${name}" | head -c 43)${short_hash}
    echo "${deploy_name}"
}
