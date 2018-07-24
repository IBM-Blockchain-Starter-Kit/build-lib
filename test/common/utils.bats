#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"

  source "${SCRIPT_DIR}/common/utils.sh"
}

@test "utils.sh: get_deploy_name should create a stable deploy name" {
  run get_deploy_name 20354d7a-e4fe-47af-8ff6-187bca92f3f9 toolchain-name network-name

  echo "output = ${output}"
  [ $status -eq 0 ]
  [ "${output}" = "toolchain-name_network-name0b9eb32" ]
}

@test "utils.sh: get_deploy_name should create a stable deploy name of 50 charaters maximum" {
  run get_deploy_name 20354d7a-e4fe-47af-8ff6-187bca92f3f9 toolchain-name looooooooooooooooooooooooooon-network-name

  echo "output = ${output}"
  [ $status -eq 0 ]
  [ "${output}" = "toolchain-name_looooooooooooooooooooooooooo188ed9f" ]
}

@test "utils.sh: get_deploy_name should work with a single argument" {
  run get_deploy_name 20354d7a-e4fe-47af-8ff6-187bca92f3f9

  echo "output = ${output}"
  [ $status -eq 0 ]
  [ "${output}" = "f95e52b" ]
}

@test "utils.sh: get_deploy_name should fail with no arguments" {
  run get_deploy_name

  echo "output = ${output}"
  [ $status -eq 1 ]
  echo "$output" | grep 'get_deploy_name must be called with at least one argument$'
}

@test "utils.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/common/utils.sh" ]
}

@test "utils.sh: should return proper values in do_curl" {
  stub cat \
      "true" \
      "true" \
      "true"
  stub curl \
      "echo 100" \
      "echo 250" \
      "echo 300"

  run do_curl
  [ $status -eq 1 ]

  run do_curl
  [ $status -eq 0 ]

  run do_curl
  [ $status -eq 1 ]

  unstub cat
  unstub curl
}
