#!/usr/bin/env bats

load test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"
}

@test "router.sh: should exist and be executable" {
  [ -x "${src_dir}/router.sh" ]
}

@test "router.sh: should fail if stage and platform arguments are not provided" {
  run ${src_dir}/router.sh

  echo $output
  [ $status -eq 1 ]

  [ "${lines[0]}" = "Invalid stage:  selected" ]
}

@test "router.sh: should fail if the platform argument is not provided" {
  run ${src_dir}/router.sh "build"

  echo $output
  [ $status -eq 1 ]
  [ "${lines[1]}" = "Invalid platform:  selected" ]
}

@test "router.sh: should fail if an invalid stage argument is provided" {
  run ${src_dir}/router.sh "foobar"

  echo $output
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "Invalid stage: foobar selected" ]
}

@test "router.sh: should accept valid stage argument (build)" {
  run ${src_dir}/router.sh "build"

  echo $output
  [ "${lines[0]}" = "build stage selected" ]
}

@test "router.sh: should accept valid stage argument (test)" {
  run ${src_dir}/router.sh "test"

  echo $output
  [ "${lines[0]}" = "test stage selected" ]
}

@test "router.sh: should accept valid stage argument (deploy)" {
  run ${src_dir}/router.sh "deploy"

  echo $output
  [ "${lines[0]}" = "deploy stage selected" ]
}

@test "router.sh: should fail if an invalid platform argument is provided" {
  run ${src_dir}/router.sh "build" "foobar"

  echo $output
  [ "$status" -eq 1 ]
  [ "${lines[1]}" = "Invalid platform: foobar selected" ]
}

@test "router.sh: should accept valid platform argument (go)" {
  stage="build"
  echo "exit 200" > "${SCRIPT_DIR}go-chaincode/${stage}.sh"

  run ${src_dir}/router.sh ${stage} "go"

  echo $output
  [ $status -eq 200 ]
  [ "${lines[1]}" = "Go selected" ]
  [ "${lines[2]}" = "${SCRIPT_DIR}go-chaincode/${stage}.sh" ]
}

@test "router.sh: should accept valid platform argument (js)" {
  stage="build"
  echo "exit 200" > "${SCRIPT_DIR}js-chaincode/${stage}.sh"

  run ${src_dir}/router.sh ${stage} "js"

  echo $output
  [ $status -eq 200 ]
  [ "${lines[1]}" = "JS selected" ]
  [ "${lines[2]}" = "${SCRIPT_DIR}js-chaincode/${stage}.sh" ]
}
