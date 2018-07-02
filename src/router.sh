# #!/bin/bash -x

# # Common pipeline build script will 
# # delegate to appropriate composer/fabric build script

stage="$1"
platform="$2"
executable_script=""

if [[ "${stage}" != "build" ]] && [[ "${stage}" != "test" ]] && [[ "${stage}" != "deploy" ]]; then
    echo "Invalid stage: ${stage} selected"
    exit 1
fi

echo "${stage} stage selected"

if [ "${platform}" = "go" ]; then
    executable_script="go-chaincode/${stage}.sh"
    echo "Go selected"
    echo ${executable_script}
elif [ "${platform}" = "composer" ]; then
    executable_script="composer/${stage}.sh"
    echo "Composer selected"
    echo ${executable_script}
else 
    echo "Invalid platform: ${platform} selected"
    exit 1
fi

source ${executable_script}
