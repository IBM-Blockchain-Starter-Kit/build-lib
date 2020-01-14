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

@test "test.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/js-chaincode/test.sh" ]
}

@test "test.sh: should run without errors" {
  echo "true" > "${SCRIPT_DIR}/common/env.sh"
  echo "unset -f nvm_install_node" >> "${SCRIPT_DIR}/common/utils.sh"
  echo "unset -f install_jq" >> "${SCRIPT_DIR}/common/utils.sh"

  source "${SCRIPT_DIR}/common/env.sh"
  source "${SCRIPT_DIR}/common/utils.sh"

  stub nvm_install_node "8.16.0 : true"
  stub install_jq "true"
  stub npm \
    "run test : true" 

  export CC_REPO_DIR="."
  export NODE_VERSION="8.16.0"
  export ADMIN_IDENTITY_STRING="[{}]"
  export CONNECTION_PROFILE_STRING="[{}]"
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

  run ${SCRIPT_DIR}/js-chaincode/test.sh

  echo $output
  [ $status -eq 0 ]

  unstub nvm_install_node
  unstub install_jq
  unstub npm
}
