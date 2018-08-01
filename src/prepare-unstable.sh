#!/usr/bin/env bash

#
# This pipeline script must be included directly in the pipeline yaml
# definition in order to fetch unreleased versions of the common
# blockchain build scripts.
#
# See also: prepare.sh
#
# Alternatively, download and extract the scripts directly in the
# repository you are building. Once they are in your own repository you
# can modify them to suit your own build requirements.
#

set -ex

build_lib_scripts="common/blockchain.sh
  common/cloudant.sh
  common/env.sh
  common/utils.sh
  composer/build.sh
  composer/deploy.sh
  composer/test.sh
  go-chaincode/build.sh
  go-chaincode/deploy.sh
  go-chaincode/download-fabric.sh
  go-chaincode/install-go.sh
  go-chaincode/test.sh
  js-chaincode/build.sh
  js-chaincode/deploy.sh
  js-chaincode/install-node.sh
  js-chaincode/test.sh
  router.sh"

mkdir -p ${SCRIPT_DIR:=./scripts/}

for script in $build_lib_scripts; do
  script_src="${SCRIPT_URL:=https://raw.githubusercontent.com/acshea/build-lib/master/src}/${script}"
  script_file="${SCRIPT_DIR}${script}"
  
  if [ ! -f  ${script_file} ]; then
    mkdir -p $(dirname "${script_file}")
    (curl -fsSL ${script_src}) > ${script_file}
  fi
done
