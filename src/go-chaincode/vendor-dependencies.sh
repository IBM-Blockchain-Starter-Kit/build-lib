#!/usr/bin/env bash

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"

$DEBUG && set -ex

# Install govendor
go get -u github.com/kardianos/govendor

#######################################
# Parses deployment configuration -> for each organization and chaincode component,
# it invokes the fetch_dependencies_cc function.
# Arguments:
#   DEPLOY_CONFIG: path to deployment JSON config file
# Returns:
#   None
#######################################
function fetch_dependencies {
    local DEPLOY_CONFIG=$1

    # Iterate over every organization and chaincode component defined in deploy config file    
    for org in $(jq -r "to_entries[] | .key" "$DEPLOY_CONFIG")
    do
        echo "Processing org '$org'..."
        jq -r ".${org}.chaincode[].path" "$DEPLOY_CONFIG" | while read -r CC_PATH
        do
            echo "About to fetch dependencies for '$CC_PATH'"
            _fetch_dependencies_cc "$CC_PATH"
        done
    done
}

#######################################
# Fetch dependencies for the specified chaincode component.
# Arguments:
#   CC_PATH: relative path to chaincode component (as defined in the deployment JSON config file)
# Returns:
#   None
#######################################
function _fetch_dependencies_cc {
    local CC_PATH=$1
    local TARGET_CC_PATH="${GOPATH}/src/$CC_PATH"
    
    pushd "$TARGET_CC_PATH"

    if [ -f ".govendor_packages" ]; then
        echo "Found .govendor_packages file."
        # Initialize govendor
        govendor init
        # Get list of packages to vendor in
        declare -a packages
        while IFS= read -r package || [ "$package" ]; do
            packages+=("$package")
        done < .govendor_packages
        local index=0

        shopt -s extglob
        while (( ${#packages[@]} > index )); do
            package=${packages[index]}
            ## Remove newlines, carriage returns
            package="${package//[$'\r\n']}"
            ### Trim leading whitespaces
            package="${package##*( )}"
            ### Trim trailing whitespaces
            package="${package%%*( )}"
            # echo "=${package}="
            if [[ -n "$package" ]]; then
                echo "Fetching ${package}"
                govendor fetch "${package}"
            fi
            (( index += 1 ))
        done
        shopt -u extglob

        echo "Copying fetched dependencies to chaincode folder..."
        cp -r vendor "$GOPATH/$CC_PATH"
    else
        echo "No .govendor_packages file found; no dependencies to vendor in."
    fi

    popd
    
    echo "Finished looking up dependencies for chaincode component."
}
