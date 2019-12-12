#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"
}

teardown() {
  cleanup_stubs
}

@test "build.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/go-chaincode/build.sh" ]
}

@test "build.sh: should run without errors" {
  echo "unset -f setup_env" >> ${SCRIPT_DIR}/common/utils.sh
  echo "unset -f install_python" >> ${SCRIPT_DIR}/common/utils.sh
  echo "unset -f nvm_install_node" >> ${SCRIPT_DIR}/common/utils.sh
  echo "unset -f install_jq" >> ${SCRIPT_DIR}/common/utils.sh

  source "${SCRIPT_DIR}/common/utils.sh"

  stub setup_env "true"
  stub install_python "2.7.15 : true"
  stub curl \
    "true" \
    "true"
  stub tar \
    "true" \
    "true"
  stub nvm_install_node "8.16.2 : true"
  stub mkdir \
    "true" \
    "true"
  stub cp "true"
  stub mv "true"
  stub npm \
    "install : true" \
    "run build : true"
  stub install_jq "true"
  stub go \
    "build -v -x chaincode/ping : true" \
    "build -v -x chaincode/woo : true"

  echo "{
    \"org1msp\": {
        \"chaincode\": [
            {
                \"path\": \"chaincode/ping\",
            },
            {
              \"path\: \"chaincode/woo\"
            }
        ],
      }
    }" > ${SCRIPT_DIR}/deploy_config.json

  mkdir -p ${SCRIPT_DIR}/chaincode/ping
  mkdir -p ${SCRIPT_DIR}/chaincode/woo

  export DEBUG=True
  export GOPATH=""
  export GOSOURCE="."
  export CHAINCODEPATH="chaincode"
  export FABRIC_CLI_DIR='.' 
  export CONFIGPATH="${SCRIPT_DIR}/deploy_config.json" 

  run ${SCRIPT_DIR}/go-chaincode/build.sh
  
  echo $output
  [ $status -eq 0 ]

  unstub setup_env
  unstub install_python
  unstub curl
  unstub tar
  unstub nvm_install_node
  unstub mkdir
  unstub cp
  unstub mv
  unstub npm
  unstub install_jq
}
