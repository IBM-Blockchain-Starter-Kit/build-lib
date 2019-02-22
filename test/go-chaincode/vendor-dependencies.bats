#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
    src_dir="${BATS_TEST_DIRNAME}/../../src"
    testcase_dirname="$(mktemp -d)"

    setup_script_dir "${src_dir}" "${testcase_dirname}"
}

@test "vendor-dependencies.sh: should exist and be executable" {
    [ -x "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh" ]
}

