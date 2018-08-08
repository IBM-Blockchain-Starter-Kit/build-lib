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
  echo "unset -f install_node" >> "${SCRIPT_DIR}/common/utils.sh"

  source "${SCRIPT_DIR}/common/utils.sh"

  stub install_node \
    "9.9.9 1.1.1 : true"
  stub npm \
    "install : true" \
    "run build : true"

  run ${SCRIPT_DIR}/js-chaincode/build.sh

  echo $output
  [ $status -eq 0 ]

  unstub install_node
  unstub npm
}
