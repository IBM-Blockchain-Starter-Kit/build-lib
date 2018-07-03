#!/usr/bin/env bats

@test "Test build stage selected" {
  run scripts/router.sh "build" ""
  [ "${lines[0]}" = "build stage selected" ]
}

@test "Test test stage selected" {
  run scripts/router.sh "test" ""
  [ "${lines[0]}" = "test stage selected" ]
}

@test "Test deploy stage selected" {
  run scripts/router.sh "deploy" ""
  [ "${lines[0]}" = "deploy stage selected" ]
}

@test "Test invalid stage selected" {
  run scripts/router.sh "foobar" ""
  [ "${lines[0]}" = "Invalid stage: foobar selected" ]
  [ "$status" -eq 1 ]
}

@test "Test go platform selected" {
  stage="build"
  run scripts/router.sh ${stage} "go"
  [ "${lines[1]}" = "Go selected" ]
  [ "${lines[2]}" = "go-chaincode/${stage}.sh" ]
}

@test "Test composer platform selected" {
  stage="build"
  run scripts/router.sh ${stage} "composer"
  [ "${lines[1]}" = "Composer selected" ]
  [ "${lines[2]}" = "composer/${stage}.sh" ]
}

@test "Test fail on invalid platform selected" {
  run scripts/router.sh "build" "foobar"
  [ "${lines[1]}" = "Invalid platform: foobar selected" ]
  [ "$status" -eq 1 ]
}
