#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"
  export GO_VERSION=9.9.9
}

teardown() {
  cleanup_stubs
}

@test "install-go.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/go-chaincode/install-go.sh" ]
}

@test "install-go.sh: should run without errors" {
  stub curl "-O https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz : true"
  stub tar "-xvf go${GO_VERSION}.linux-amd64.tar.gz : true"

  run "${SCRIPT_DIR}/go-chaincode/install-go.sh"

  echo $output
  [ $status -eq 0 ]

  unstub curl
  unstub tar
}
