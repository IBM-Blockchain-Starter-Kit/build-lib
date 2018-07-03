#!/usr/bin/env bats

@test "build.sh: Should not overwrite existing chaincode src dir contents" {
  run "scripts/go-chaincode/build.sh"
}

@test "build.sh: Should install hyperledger fabric go package" {
  # [ true = true ]
}
