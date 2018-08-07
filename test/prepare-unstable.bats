#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../bats-mock/stub.bash"
load test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../src"
  testcase_dirname="$(mktemp -d)"

  export SCRIPT_URL="https://example.org/scripts"
  export SCRIPT_DIR="${testcase_dirname}/script_dir/"
}

teardown() {
  cleanup_stubs
}

stub_curl_all() {
  stub curl \
    "-fsSL https://example.org/scripts/common/blockchain.sh : cat ${src_dir}/common/blockchain.sh" \
    "-fsSL https://example.org/scripts/common/cloudant.sh : cat ${src_dir}/common/cloudant.sh" \
    "-fsSL https://example.org/scripts/common/env.sh : cat ${src_dir}/common/env.sh" \
    "-fsSL https://example.org/scripts/common/utils.sh : cat ${src_dir}/common/utils.sh" \
    "-fsSL https://example.org/scripts/composer/build.sh : cat ${src_dir}/composer/build.sh" \
    "-fsSL https://example.org/scripts/composer/deploy.sh : cat ${src_dir}/composer/deploy.sh" \
    "-fsSL https://example.org/scripts/composer/test.sh : cat ${src_dir}/composer/test.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/build.sh : cat ${src_dir}/go-chaincode/build.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/deploy.sh : cat ${src_dir}/go-chaincode/deploy.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/download-fabric.sh : cat ${src_dir}/go-chaincode/download-fabric.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/install-go.sh : cat ${src_dir}/go-chaincode/install-go.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/test.sh : cat ${src_dir}/go-chaincode/test.sh" \
    "-fsSL https://example.org/scripts/js-chaincode/build.sh : cat ${src_dir}/js-chaincode/build.sh" \
    "-fsSL https://example.org/scripts/js-chaincode/deploy.sh : cat ${src_dir}/js-chaincode/deploy.sh" \
    "-fsSL https://example.org/scripts/js-chaincode/test.sh : cat ${src_dir}/js-chaincode/test.sh" \
    "-fsSL https://example.org/scripts/router.sh : cat ${src_dir}/router.sh"
}

stub_curl_without_router() {
  stub curl \
    "-fsSL https://example.org/scripts/common/blockchain.sh : cat ${src_dir}/common/blockchain.sh" \
    "-fsSL https://example.org/scripts/common/cloudant.sh : cat ${src_dir}/common/cloudant.sh" \
    "-fsSL https://example.org/scripts/common/env.sh : cat ${src_dir}/common/env.sh" \
    "-fsSL https://example.org/scripts/common/utils.sh : cat ${src_dir}/common/utils.sh" \
    "-fsSL https://example.org/scripts/composer/build.sh : cat ${src_dir}/composer/build.sh" \
    "-fsSL https://example.org/scripts/composer/deploy.sh : cat ${src_dir}/composer/deploy.sh" \
    "-fsSL https://example.org/scripts/composer/test.sh : cat ${src_dir}/composer/test.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/build.sh : cat ${src_dir}/go-chaincode/build.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/deploy.sh : cat ${src_dir}/go-chaincode/deploy.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/download-fabric.sh : cat ${src_dir}/go-chaincode/download-fabric.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/install-go.sh : cat ${src_dir}/go-chaincode/install-go.sh" \
    "-fsSL https://example.org/scripts/go-chaincode/test.sh : cat ${src_dir}/go-chaincode/test.sh" \
    "-fsSL https://example.org/scripts/js-chaincode/build.sh : cat ${src_dir}/js-chaincode/build.sh" \
    "-fsSL https://example.org/scripts/js-chaincode/deploy.sh : cat ${src_dir}/js-chaincode/deploy.sh" \
    "-fsSL https://example.org/scripts/js-chaincode/test.sh : cat ${src_dir}/js-chaincode/test.sh"
}

@test "prepare-unstable.sh: should exist and be executable" {
  [ -x "${src_dir}/prepare-unstable.sh" ]
}

@test "prepare-unstable.sh: should run without errors" {
  stub_curl_all

  run "${src_dir}/prepare-unstable.sh"
  
  echo $output
  [ $status -eq 0 ]

  unstub curl
}

@test "prepare-unstable.sh: should create SCRIPT_DIR if it does not exist already" {
  stub_curl_all

  run "${src_dir}/prepare-unstable.sh"

  [ -d "${SCRIPT_DIR}" ]

  unstub curl
}

@test "prepare-unstable.sh: should only create expected script files" {
  stub_curl_all

  run "${src_dir}/prepare-unstable.sh"

  assert_build_scripts_exist "${src_dir}" "${SCRIPT_DIR}"

  unstub curl
}

@test "prepare-unstable.sh: should not overwrite existing scripts in SCRIPT_DIR" {
  stub_curl_without_router

  mkdir -p "${SCRIPT_DIR}"
  echo "DO NOT OVERWRITE" > "${SCRIPT_DIR}router.sh"

  run "${src_dir}/prepare-unstable.sh"

  head -n 1 "${SCRIPT_DIR}router.sh"
  cat "${SCRIPT_DIR}router.sh" | grep -Fxq 'DO NOT OVERWRITE'

  unstub curl
}
