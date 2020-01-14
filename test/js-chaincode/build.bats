#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"

  export NODE_VERSION=9.9.9
  export NVM_VERSION=1.1.1
}

teardown() {
  cleanup_stubs
}

@test "build.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/js-chaincode/build.sh" ]
}

@test "build.sh: should run without errors" {
  echo "true" > "${SCRIPT_DIR}/common/env.sh"
  echo "unset -f setup_env" >> "${SCRIPT_DIR}/common/utils.sh"  
  echo "unset -f install_python" >> "${SCRIPT_DIR}/common/utils.sh"  
  echo "unset -f nvm_install_node" >> "${SCRIPT_DIR}/common/utils.sh"  
  echo "unset -f install_jq" >> ${SCRIPT_DIR}/common/utils.sh

  source "${SCRIPT_DIR}/common/env.sh"
  source "${SCRIPT_DIR}/common/utils.sh"

  stub setup_env "true"
  stub install_python "2.7.15 : true"
  stub nvm_install_node "8.16.0 : true"
  stub npm \
    "install : true" \
    "run build : true" \
    "install : true" \
    "run build : true"
  stub install_jq "true"

  export CC_REPO_DIR="."
  export PYTHON_VERSION="2.7.15"
  export NODE_VERSION="8.16.0"
  export FABRIC_CLI_DIR="."

  export CONFIGPATH="${SCRIPT_DIR}/deploy_config.json" 

  echo "{
    \"org1msp\": {
        \"chaincode\": [
            {
                \"path\": \"chaincode/ping\"
            }
        ]
      }
    }" > ${SCRIPT_DIR}/deploy_config.json
  
  mkdir -p ${CC_REPO_DIR}/chaincode/ping


  run ${SCRIPT_DIR}/js-chaincode/build.sh

  echo $output
  [ $status -eq 0 ]

  unstub setup_env
  unstub install_python
  unstub nvm_install_node
  unstub npm  
  unstub install_jq
}
