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
  stub curl \
    "true" \
    "true"
  stub go "build -v -x chaincode/... : true"
  stub tar \
    "true" \
    "true"

  pushd ${SCRIPT_DIR}
  run "./go-chaincode/build.sh"
  [ $status -eq 0 ]
  popd

  unstub curl
  unstub go
  unstub tar
}
