#!/usr/bin/env bash

echo "######## Test chaincode ########"



# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"
# source "${SCRIPT_DIR}/go-chaincode/install-go.sh"
source "${SCRIPT_DIR}/common/utils.sh"

echo "######## Download dependencies ########"
setup_env

$DEBUG && set -x

# Install assert package for GO (needed for testing)
echo "=> go get assert"
go version
go get github.com/stretchr/testify/assert

# Install go-junit-report
echo "=> go get go-junit-report"
go get -u github.com/jstemmer/go-junit-report

# Run test cases and send results to go-junit-report
#go test -v "chaincode/..."
echo '=> check $GOPATH/src/chaincode directory'
ls "$GOPATH/src/chaincode"


# echo "=> go test -v chaincode"
# TODO: 
# - try running just go test
go test -v "chaincode/..." 2>&1 | tee tst-output.txt | go-junit-report > TEST-report.xml
# go test -v "chaincode/..."

# echo "=> ls output from test"
# ls | grep tst-output.txt
# ls | grep TEST-report.xml
# go test -v "local/ping-cc/..." 2>&1 | tee tst-output.txt | go-junit-report > TEST-report.xml
cat tst-output.txt
