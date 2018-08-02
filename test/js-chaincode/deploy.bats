#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"
}

@test "deploy.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/js-chaincode/deploy.sh" ]
}

@test "deploy.sh: should fail if deploy configuration does not exist" {
  export CONFIGPATH="fakepath"

  run "${SCRIPT_DIR}/js-chaincode/deploy.sh"
  [ "$output" = "No deploy configuration at specified path: fakepath" ]
  [ $status -eq 1 ]
}

@test "deploy.sh: should succeed if deploy configuration exists" {
  export CONFIGPATH=$(mktemp)

  echo "unset -f install_jq" >> "${SCRIPT_DIR}/common/utils.sh"
  echo "unset -f setup_service_constants" >> "${SCRIPT_DIR}/common/blockchain.sh"
  echo "unset -f provision_blockchain" >> "${SCRIPT_DIR}/common/blockchain.sh"
  echo "unset -f deploy_fabric_chaincode" >> "${SCRIPT_DIR}/common/blockchain.sh"

  source "${SCRIPT_DIR}/common/utils.sh"
  source "${SCRIPT_DIR}/common/blockchain.sh"

  stub install_jq "true"
  stub setup_service_constants "true"
  stub provision_blockchain "true"
  stub deploy_fabric_chaincode "true"

  run ${SCRIPT_DIR}/js-chaincode/deploy.sh

  [ $status -eq 0 ]

  unstub install_jq
  unstub setup_service_constants
  unstub provision_blockchain
  unstub deploy_fabric_chaincode
}
