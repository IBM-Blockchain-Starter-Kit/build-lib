#!/usr/bin/env bats

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
  CHAINCODEPATH="ccpath"  
  CONFIGPATH="path"
  DEBUG=true

  source "${SCRIPT_DIR}/common/env.sh"
  
  echo $CHAINCODEPATH
  [ "${CHAINCODEPATH}" == "ccpath" ]
  [ "${CONFIGPATH}" = "path" ]
  [ "${GOPATH}" = "test" ]
  [ "${GOROOT}" = "test/go" ]
  [ "${GO_VERSION}" = "1.0.0" ]
  [ "${HLF_VERSION}" = "2.0.0" ]
  [ "${FABRIC_SRC_DIR}" = "test/fabric-2.0.0" ]
  [ "${DEBUG}" = true ]

}

@test "env.sh: should accept default values" {
  
  source "${SCRIPT_DIR}/common/env.sh"
  
  [ "${CONFIGPATH}" = "${CC_REPO_DIR}/deploy_config.json" ]  
  [ "${GOPATH}" = "${PWD}" ]
  [ "${GOROOT}" = "${PWD}/go" ]
  [ "${GO_VERSION}" = "1.12" ]
  [ "${HLF_VERSION}" = "1.4.4" ]
  [ "${FABRIC_SRC_DIR}" = "${PWD}/fabric-1.4.4" ]
  [ "${DEBUG}" = false ]

}

@test "env.sh: HLF_VERSION should be a valid Hyperledger Fabric version" {
  source "${SCRIPT_DIR}/common/env.sh"

  run curl -fIL https://github.com/hyperledger/fabric/archive/v${HLF_VERSION}.tar.gz

  echo "$output"
  [ $status -eq 0 ]
}
