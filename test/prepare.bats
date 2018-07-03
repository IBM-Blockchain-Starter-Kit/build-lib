#!/usr/bin/env bats

@test "Test scripts directory created, if it does not exist" {
    rm -rf scripts/
    run "src/prepare.sh"
    [ -e scripts/ ]
    rm -rf scripts/
}

@test "Test go chaincode was downloaded" {
    rm -rf scripts/
    run "src/prepare.sh"
    [ -f scripts/router.sh ]
    [ -d scripts/go-chaincode ]
    [ -f scripts/go-chaincode/build.sh ]
    [ -f scripts/go-chaincode/test.sh ]
    [ -f scripts/go-chaincode/deploy.sh ]
    rm -rf scripts/
}
