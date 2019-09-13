#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"

  source "${SCRIPT_DIR}/common/utils.sh"
}

teardown() {
  cleanup_stubs
}

@test "utils.sh: should exist and be executable" {
  [ -x "${SCRIPT_DIR}/common/utils.sh" ]
}

@test "utils.sh: error_exit should exit 1 with a default error message" {
  run error_exit

  echo "$output"
  [ $status -eq 1 ]
  [ "${output}" = "Unknown Error" ]
}

@test "utils.sh: error_exit should exit 1 with the provided error message" {
  run error_exit "R Tape loading error, 0:1"

  echo "$output"
  [ $status -eq 1 ]
  [ "${output}" = "R Tape loading error, 0:1" ]
}

# @test "utils.sh: get_deploy_name should create a stable deploy name" {
#   run get_deploy_name 20354d7a-e4fe-47af-8ff6-187bca92f3f9 toolchain-name network-name

#   echo "output = ${output}"
#   [ $status -eq 0 ]
#   [ "${output}" = "toolchain-name_network-name0b9eb32" ]
# }

# @test "utils.sh: get_deploy_name should create a stable deploy name of 50 charaters maximum" {
#   run get_deploy_name 20354d7a-e4fe-47af-8ff6-187bca92f3f9 toolchain-name looooooooooooooooooooooooooon-network-name

#   echo "output = ${output}"
#   [ $status -eq 0 ]
#   [ "${output}" = "toolchain-name_looooooooooooooooooooooooooo188ed9f" ]
# }

# @test "utils.sh: get_deploy_name should work with a single argument" {
#   run get_deploy_name 20354d7a-e4fe-47af-8ff6-187bca92f3f9

#   echo "output = ${output}"
#   [ $status -eq 0 ]
#   [ "${output}" = "f95e52b" ]
# }

# @test "utils.sh: get_deploy_name should fail with no arguments" {
#   run get_deploy_name

#   echo "output = ${output}"
#   [ $status -eq 1 ]
#   echo "$output" | grep 'get_deploy_name must be called with at least one argument$'
# }

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

@test "utils.sh: retry_with_backoff should run a successful command once" {
  stub successful_command \
    "true"

  run retry_with_backoff 0 successful_command
  [ $status -eq 0 ]

  unstub successful_command
}

@test "utils.sh: retry_with_backoff should rerun a command until it succeeds" {
  stub sleep \
    "1 : true" \
    "2 : true"

  stub unreliable_command \
    "false" \
    "false" \
    "true"

  run retry_with_backoff 0 unreliable_command
  [ $status -eq 0 ]

  unstub sleep
  unstub unreliable_command
}

@test "utils.sh: retry_with_backoff should fail if a command does not succeed in default number of attempts if the first argument is 0" {
  stub sleep \
    "1 : true" \
    "2 : true" \
    "4 : true" \
    "8 : true"

  stub failing_command \
    "false" \
    "false" \
    "false" \
    "false" \
    "false"

  run retry_with_backoff 0 failing_command
  [ $status -eq 1 ]

  unstub sleep
  unstub failing_command
}

@test "utils.sh: retry_with_backoff should fail if a command does not succeed in default number of attempts if the first argument is negative" {
  stub sleep \
    "1 : true" \
    "2 : true" \
    "4 : true" \
    "8 : true"

  stub failing_command \
    "false" \
    "false" \
    "false" \
    "false" \
    "false"

  run retry_with_backoff -1 failing_command
  [ $status -eq 1 ]

  unstub sleep
  unstub failing_command
}

@test "utils.sh: retry_with_backoff should fail if a command does not succeed in default number of attempts if the first argument is not a number" {
  stub sleep \
    "1 : true" \
    "2 : true" \
    "4 : true" \
    "8 : true"

  stub failing_command \
    "false" \
    "false" \
    "false" \
    "false" \
    "false"

  run retry_with_backoff muppet failing_command
  [ $status -eq 1 ]

  unstub sleep
  unstub failing_command
}

@test "utils.sh: retry_with_backoff should fail if a command does not succeed in specified number of attempts" {
  stub sleep \
    "1 : true" \
    "2 : true" \
    "4 : true" \
    "8 : true" \
    "16 : true" \
    "32 : true" \
    "64 : true"

  stub failing_command \
    "false" \
    "false" \
    "false" \
    "false" \
    "false" \
    "false" \
    "false" \
    "false"

  run retry_with_backoff 8 failing_command
  [ $status -eq 1 ]

  unstub sleep
  unstub failing_command
}


