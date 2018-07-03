#!/usr/bin/env bats

@test "router.bats: build stage selected" {
  run src/router.sh "build" ""
  [ "${lines[0]}" = "build stage selected" ]
}

@test "router.bats: test stage selected" {
  run src/router.sh "test" ""
  [ "${lines[0]}" = "test stage selected" ]
}

@test "router.bats: deploy stage selected" {
  run src/router.sh "deploy" ""
  [ "${lines[0]}" = "deploy stage selected" ]
}

@test "router.bats: invalid stage selected" {
  run src/router.sh "foobar" ""
  [ "${lines[0]}" = "Invalid stage: foobar selected" ]
  [ "$status" -eq 1 ]
}

@test "router.bats: go platform selected" {
  stage="build"
  run src/router.sh ${stage} "go"
  [ "${lines[1]}" = "Go selected" ]
  [ "${lines[2]}" = "go-chaincode/${stage}.sh" ]
}

@test "router.bats: composer platform selected" {
  stage="build"
  run src/router.sh ${stage} "composer"
  [ "${lines[1]}" = "Composer selected" ]
  [ "${lines[2]}" = "composer/${stage}.sh" ]
}

@test "router.bats: fail on invalid platform selected" {
  run src/router.sh "build" "foobar"
  [ "${lines[1]}" = "Invalid platform: foobar selected" ]
  [ "$status" -eq 1 ]
}
