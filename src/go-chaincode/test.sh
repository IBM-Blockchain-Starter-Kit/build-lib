#!/usr/bin/env bash

echo "######## Test chaincode ########"

# shellcheck source=src/common/env.sh
source "${SCRIPT_DIR}/common/env.sh"

$DEBUG && set -x

# Install assert package for GO (needed for testing)
go get github.com/stretchr/testify/assert
# Install go-junit-report
go get -u github.com/jstemmer/go-junit-report
# Run test cases and send output/results to terminal and go-junit-report
#go test -v "chaincode/..."
go test -v "chaincode/..." 2>&1 | tee raw-output.txt | "$GOPATH"/bin/go-junit-report > TEST-report.xml
cat raw-output.txt
