#!/usr/bin/env bash

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
