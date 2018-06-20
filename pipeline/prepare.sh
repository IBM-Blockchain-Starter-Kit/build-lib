#!/bin/bash
default_scripts="build.sh
deploy-enterprise.sh
download-fabric.sh
install-go.sh
unitest.sh
env.sh"

if [ ! -f  ${SCRIPT_DIR:=./scripts/} ]; then
  mkdir -p ${SCRIPT_DIR}
fi

for script in ${BUILD_SCRIPTS:=$default_scripts}; do
  SCRIPT_SRC="${SCRIPT_URL:=https://raw.githubusercontent.com/yorhodes/build-lib/fabric/pipeline}/${script}"
  SCRIPT_FILE="${SCRIPT_DIR}${script}"
  
  if [ ! -f  ${SCRIPT_FILE} ]; then
    echo -e "No script found at ${SCRIPT_FILE}, defaulting to ${SCRIPT_SRC}"
    (curl -sSL ${SCRIPT_SRC}) > ${SCRIPT_FILE}
  else
    echo "Script found at ${SCRIPT_FILE}"
  fi
done

mkdir build
cd build

source ${SCRIPT_DIR}install-go.sh
source ${SCRIPT_DIR}download-fabric.sh