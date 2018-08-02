#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"
  export NODE_VERSION=9.9.9
  export NVM_VERSION=1.1.1
  export NVM_DIR="nvm_dir"
}

teardown() {
  cleanup_stubs
}

@test "install-node.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/js-chaincode/install-node.sh" ]
}

@test "install-node.sh: should run without errors" {
  skip
}
