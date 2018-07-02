#!/bin/bash

set -ex

SCRIPT_URL=${SCRIPT_URL:=https://raw.githubusercontent.com/IBM-Blockchain-Starter-Kit/build-lib/master/src}
SCRIPT_DIR=${SCRIPT_DIR:=./scripts/}

# $1 should be a string of file names separated by '\n'
function fetch_scripts {
  if [ ! -f  ${SCRIPT_DIR} ]; then
    mkdir -p ${SCRIPT_DIR}
  fi

  for script_name in $1; do
    SCRIPT_SRC="${SCRIPT_URL}/${script_name}"
    SCRIPT_FILE="${SCRIPT_DIR}/${script_name}"

    if [ ! -f  ${SCRIPT_FILE} ];
    then
      echo -e "No script found at ${SCRIPT_FILE}, defaulting to ${SCRIPT_SRC}"
      mkdir -p $(dirname "${SCRIPT_FILE}")
      (curl -sSL ${SCRIPT_SRC}) > ${SCRIPT_FILE}
    else
      echo "Script found at ${SCRIPT_FILE}"
    fi
  done
}

function run_scripts {
  for script_name in $1; do
    source "${SCRIPT_DIR}/${script_name}"
  done
}

fetch_scripts "router.sh
go-chaincode/build.sh
go-chaincode/test.sh
go-chaincode/deploy.sh"

pwd
ls

#sleep 300000000