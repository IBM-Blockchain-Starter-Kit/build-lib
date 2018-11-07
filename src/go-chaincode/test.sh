#!/usr/bin/env bash

echo "######## Test chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"

$DEBUG && set -x

# Install assert package for GO (needed for testing)
go get github.com/stretchr/testify/assert
# Install go-junit-report
go get -u github.com/jstemmer/go-junit-report
# Run test cases and send results to go-junit-report
#go test -v "chaincode/..."
go test -v "chaincode/..." 2>&1 | tee tst-output.txt | go-junit-report > TEST-report.xml
cat tst-output.txt
