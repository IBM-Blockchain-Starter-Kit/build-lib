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
  [ -x "${SCRIPT_DIR}/go-chaincode/test.sh" ]
}

@test "test.sh: should run without errors" {
  stub go "test -v chaincode : true"

  run "${SCRIPT_DIR}/go-chaincode/test.sh"

  echo $output
  [ $status -eq 0 ]

  unstub go
}