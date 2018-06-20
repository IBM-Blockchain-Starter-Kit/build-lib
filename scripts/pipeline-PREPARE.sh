#!/bin/bash

set -ex

default_scripts="pipeline-BLOCKCHAIN.sh
pipeline-BUILD.sh
pipeline-CLOUDANT.sh
pipeline-COMMON.sh
pipeline-DEPLOY.sh"

if [ ! -f  ${SCRIPT_DIR:=./scripts/} ]; then
  mkdir -p ${SCRIPT_DIR}
fi

for script in ${BUILD_SCRIPTS:=$default_scripts}; do
  SCRIPT_SRC="${SCRIPT_URL:=https://raw.githubusercontent.com/IBM-Blockchain-Starter-Kit/build-lib/master/scripts}/${script}"
  SCRIPT_FILE="${SCRIPT_DIR}${script}"
  
  if [ ! -f  ${SCRIPT_FILE} ]; then
    echo -e "No script found at ${SCRIPT_FILE}, defaulting to ${SCRIPT_SRC}"
    (curl -sSL ${SCRIPT_SRC}) > ${SCRIPT_FILE}
  else
    echo "Script found at ${SCRIPT_FILE}"
  fi
done
