#!/usr/bin/env bats

setup() {
  src_dir="scripts"
}

@test "router.sh: build stage selected" {
  run ${src_dir}/router.sh "build" ""
  [ "${lines[0]}" = "build stage selected" ]
}

@test "router.sh: test stage selected" {
  run ${src_dir}/router.sh "test" ""
  [ "${lines[0]}" = "test stage selected" ]
}

@test "router.sh: deploy stage selected" {
  run ${src_dir}/router.sh "deploy" ""
  [ "${lines[0]}" = "deploy stage selected" ]
}

@test "router.sh: invalid stage selected" {
  run ${src_dir}/router.sh "foobar" ""
  [ "${lines[0]}" = "Invalid stage: foobar selected" ]
  [ "$status" -eq 1 ]
}

@test "router.sh: go platform selected" {
  stage="build"
  run ${src_dir}/router.sh ${stage} "go"
  [ "${lines[1]}" = "Go selected" ]
  [ "${lines[2]}" = "go-chaincode/${stage}.sh" ]
}

@test "router.sh: composer platform selected" {
  stage="build"
  run ${src_dir}/router.sh ${stage} "composer"
  [ "${lines[1]}" = "Composer selected" ]
  [ "${lines[2]}" = "composer/${stage}.sh" ]
}

@test "router.sh: fail on invalid platform selected" {
  run ${src_dir}/router.sh "build" "foobar"
  [ "${lines[1]}" = "Invalid platform: foobar selected" ]
  [ "$status" -eq 1 ]
}
