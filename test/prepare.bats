#!/usr/bin/env bats

@test "Test scripts directory created, if it does not exist" {
    rm -rf $BATS_TEST_DIRNAME/scripts/
    run "../src/prepare.sh"
    [ -e $BATS_TEST_DIRNAME/scripts/ ]
    rm -rf $BATS_TEST_DIRNAME/scripts/
}

@test "Test go chaincode was downloaded" {
    rm -rf $BATS_TEST_DIRNAME/scripts/
    run "../src/prepare.sh"
    [ -f $BATS_TEST_DIRNAME/scripts/router.sh ]
    [ -d $BATS_TEST_DIRNAME/scripts/go-chaincode ]
    [ -f $BATS_TEST_DIRNAME/scripts/go-chaincode/build.sh ]
    [ -f $BATS_TEST_DIRNAME/scripts/go-chaincode/test.sh ]
    [ -f $BATS_TEST_DIRNAME/scripts/go-chaincode/deploy.sh ]
    rm -rf $BATS_TEST_DIRNAME/scripts/
}