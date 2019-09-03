#!/bin/bash 

# Common pipeline build script will 
# delegate to appropriate build script
# script receives two parameters, the stage to route  
# and the platform 

stage="$1"
platform="$2"
executable_script=""

if [[ "${stage}" != "build" ]] && [[ "${stage}" != "test" ]] && [[ "${stage}" != "deploy" ]]; then
    echo "Invalid stage: ${stage} selected"
    exit 1
fi

echo "${stage} stage selected"

if [ "${platform}" = "go" ]; then
    executable_script="${SCRIPT_DIR}/src/go-chaincode/${stage}.sh"
    echo "Go selected"
    echo "$executable_script"
elif [ "${platform}" = "js" ]; then
    executable_script="${SCRIPT_DIR}/src/js-chaincode/${stage}.sh"
    echo "JS selected"
    echo "${executable_script}"
else 
    echo "Invalid platform: ${platform} selected"
    exit 1
fi

# ok now let's call the command we are routing to
# shellcheck disable=1090
source "$executable_script"
