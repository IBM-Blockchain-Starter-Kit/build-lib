#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"

  export HLF_VERSION=9.9.9
}

teardown() {
  cleanup_stubs
}

@test "download-fabric.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/go-chaincode/download-fabric.sh" ]
}

@test "download-fabric.sh: should run without errors" {
  stub curl "-O -L https://github.com/hyperledger/fabric/archive/v9.9.9.tar.gz : true"
  stub tar "-xvf v9.9.9.tar.gz : true"

  run "${SCRIPT_DIR}/go-chaincode/download-fabric.sh"

  echo $output
  [ $status -eq 0 ]

  unstub curl
  unstub tar
}
