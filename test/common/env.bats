#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"
}

@test "env.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/common/env.sh" ]
}

@test "env.sh: should run without errors" {
  
  run "${SCRIPT_DIR}/common/env.sh"

  echo $output
  [ $status -eq 0 ]

}

@test "env.sh: should accept non-default values" {

  ROOTDIR="test"
  GO_VERSION="1.0.0"
  HLF_VERSION="2.0.0"

  source "${SCRIPT_DIR}/common/env.sh"

  [ "${GOPATH}" = "test" ]
  [ "${GOROOT}" = "test/go" ]
  [ "${GO_VERSION}" = "1.0.0" ]
  [ "${HLF_VERSION}" = "2.0.0" ]
  [ "${FABRIC_SRC_DIR}" = "test/fabric-2.0.0" ]

}

@test "env.sh: should accept default values" {
  
  source "${SCRIPT_DIR}/common/env.sh"

  [ "${GOPATH}" = "${PWD}" ]
  [ "${GOROOT}" = "${PWD}/go" ]
  [ "${GO_VERSION}" = "1.9.2" ]
  [ "${HLF_VERSION}" = "1.0.4" ]
  [ "${FABRIC_SRC_DIR}" = "${PWD}/fabric-1.0.4" ]

}
