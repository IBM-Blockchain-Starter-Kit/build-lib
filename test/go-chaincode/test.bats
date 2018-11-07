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
  stub go \
    "get github.com/stretchr/testify/assert : true" \
    "get -u github.com/jstemmer/go-junit-report : true" \
    "test -v chaincode/... : true"
  stub go-junit-report "echo 'GO tests resports created!'"

  run "${SCRIPT_DIR}/go-chaincode/test.sh"

  echo $output
  [ $status -eq 0 ]

  unstub go
  unstub go-junit-report
}