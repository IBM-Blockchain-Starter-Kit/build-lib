#!/usr/bin/env bats

setup() {
  src_dir="scripts"
}

@test "build.sh: should exist and be executable" {
  [ -x "${src_dir}/go-chaincode/build.sh" ]
}

@test "build.sh: should install fabric STUB" {
  skip
}

@test "build.sh: should install go STUB" {
  skip
}

@test "build.sh: should not overwrite existing chaincode src dir contents" {
  output1=$(ls "src")
  run "${src_dir}/go-chaincode/build.sh"
  skip "$output"
  [ true = false ]
  #output2=$(ls "src")
  #[ ${output1} = ${output2} ]
}

@test "build.sh: should add hyperledger fabric as go package STUB" {

  # [ true = true ]
}
