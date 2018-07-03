#!/usr/bin/env bats

@test "router.sh: build stage selected" {
  run src/router.sh "build" ""
  [ "${lines[0]}" = "build stage selected" ]
}

@test "router.sh: test stage selected" {
  run src/router.sh "test" ""
  [ "${lines[0]}" = "test stage selected" ]
}

@test "router.sh: deploy stage selected" {
  run src/router.sh "deploy" ""
  [ "${lines[0]}" = "deploy stage selected" ]
}

@test "router.sh: invalid stage selected" {
  run src/router.sh "foobar" ""
  [ "${lines[0]}" = "Invalid stage: foobar selected" ]
  [ "$status" -eq 1 ]
}

@test "router.sh: go platform selected" {
  stage="build"
  run scripts/router.sh ${stage} "go"
  [ "${lines[1]}" = "Go selected" ]
  [ "${lines[2]}" = "go-chaincode/${stage}.sh" ]
}

@test "router.sh: composer platform selected" {
  stage="build"
  run scripts/router.sh ${stage} "composer"
  [ "${lines[1]}" = "Composer selected" ]
  [ "${lines[2]}" = "composer/${stage}.sh" ]
}

<<<<<<< HEAD
@test "router.sh: fail on invalid platform selected" {
  run src/router.sh "build" "foobar"
=======
@test "Test fail on invalid platform selected" {
  run scripts/router.sh "build" "foobar"
>>>>>>> pair
  [ "${lines[1]}" = "Invalid platform: foobar selected" ]
  [ "$status" -eq 1 ]
}
