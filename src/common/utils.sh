#!/usr/bin/env bash

# Common utility functions, e.g. to make curl requests

#######################################
# Creates and displays a name that is likely to be unique and suitable for use
# when deploying apps to bluemix
# Globals:
#   None
# Arguments:
#   uuid: Universally unique identifier
#   name: Additional name arguments
# Returns:
#   None
#######################################
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

#######################################
# Installs jq using curl and updates path
# Globals:
#   set: PATH
# Arguments:
#   None
# Returns:
#   None
#######################################
function install_jq {
    curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
    chmod +x jq
    export PATH=${PATH}:${PWD}
}

#######################################
# Performs curl request, displays response, and returns status
# Globals:
#   None
# Arguments:
#   $@: Curl options
# Returns:
#   err_no:
#     1 = http status code is between 200 and 299 inclusive, indicating success
#     0 = http status code is less than 200, indicating an informational response, or
#         greater than 299, indicating redirection or error
#######################################
function do_curl {
    HTTP_RESPONSE=$(mktemp)
    HTTP_STATUS=$(curl -w '%{http_code}' -o "${HTTP_RESPONSE}" "$@")
    cat "${HTTP_RESPONSE}"
    rm -f "${HTTP_RESPONSE}"
    if [[ ${HTTP_STATUS} -ge 200 && ${HTTP_STATUS} -lt 300 ]]
    then
        return 0
    else
        return 1
    fi
}
