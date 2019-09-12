#!/usr/bin/env bash

echo "######## Test chaincode ########"



# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"
# source "${SCRIPT_DIR}/go-chaincode/install-go.sh"

echo "======== Download dependencies ========"
setup_env

$DEBUG && set -x

# Install assert package for GO (needed for testing)
echo "=> go get assert"
go get github.com/stretchr/testify/assert

# Install go-junit-report
echo "=> go get go-junit-report"
go get -u github.com/jstemmer/go-junit-report

# Run test cases and send results to go-junit-report
echo '=> check GOPATH/src/chaincode directory'
ls "$GOPATH/src/chaincode"


# TODO: 
echo "======== Run cc tests ========"
go test -v "chaincode/..." 2>&1 | tee tst-output.txt | go-junit-report > TEST-report.xml
cat tst-output.txt
