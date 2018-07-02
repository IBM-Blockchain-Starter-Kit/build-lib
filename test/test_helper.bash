#!/usr/bin/env bash

function count_files {
  # Recursively count files under the specified directory
  test_dirname=$1

  echo $(cd "${test_dirname}" && find .//. -type f ! -name . -print | grep -c //)
}

function assert_build_scripts_exist {
  test_dirname=$1
  
  build_lib_scripts="common/blockchain.sh
    common/cloudant.sh
    common/env.sh
    common/utils.sh
    composer/build.sh
    composer/deploy.sh
    composer/test.sh
    go-chaincode/build.sh
    go-chaincode/deploy.sh
    go-chaincode/test.sh
    build.sh
    deploy.sh
    test.sh"

  for script in $build_lib_scripts; do
    script_path="${test_dirname}/${script}"
    echo "${script_path} should exist"
    [ -f "${script_path}" ]
  done
}
