#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
    src_dir="${BATS_TEST_DIRNAME}/../../src"
    testcase_dirname="$(mktemp -d)"

    setup_script_dir "${src_dir}" "${testcase_dirname}"

    testcase_gopath=${testcase_dirname}/go
    echo "export GOPATH=${testcase_gopath}" >> "${SCRIPT_DIR}/common/env.sh"
}

teardown() {
    cleanup_stubs
}

@test "vendor-dependencies.sh: should exist and be executable" {
    [ -x "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh" ]
}

@test "vendor-dependencies.sh: fetch_dependencies should run without errors when .govendor_packages file does not exist" {

    mkdir -p "${testcase_gopath}/src"
    cat << EOF > "${testcase_gopath}/src/sample-config.json"
{
  "org1": {
    "chaincode": [
      {
        "name": "contract1",
        "path": "chaincode/contract1",
        "channels": [ "channel1" ],
        "init_args": [],
        "instantiate": false,
        "install": true
      }
    ]
  },
  "org2": {
    "chaincode": [
      {
        "name": "contract1",
        "path": "chaincode/contract1",
        "channels": [ "channel1" ],
        "init_args": [],
        "instantiate": false,
        "install": true
      }
    ]
  }
}
EOF

    mkdir -p "${testcase_gopath}/src/chaincode/contract1"
    
    stub go \
        "get -u github.com/kardianos/govendor : true"

    source "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh"

    run fetch_dependencies "${testcase_gopath}/src/sample-config.json"
 
    # Assertions
    echo $output
    unstub go
    [ $status -eq 0 ]  
    [ "${lines[0]}" = "Processing org 'org1'..." ]
    [ "${lines[1]}" = "About to fetch dependencies for 'chaincode/contract1'" ]
    [ "${lines[3]}" = "No .govendor_packages file found; no dependencies to vendor in." ]

    [ "${lines[6]}" = "Processing org 'org2'..." ]
    [ "${lines[7]}" = "About to fetch dependencies for 'chaincode/contract1'" ]
    [ "${lines[9]}" = "No .govendor_packages file found; no dependencies to vendor in." ]  
}

@test "vendor-dependencies.sh: fetch_dependencies should run without errors when .govendor_packages file has new lines and white spaces; also testing with multiple .govendor_packages file (one per chaincode component)" {

    mkdir -p "${testcase_gopath}/src"
    cat << EOF > "${testcase_gopath}/src/sample-config.json"
{
  "org1": {
    "chaincode": [
      {
        "name": "contract1",
        "path": "chaincode/contract1",
        "channels": [ "channel1" ],
        "init_args": [],
        "instantiate": false,
        "install": true
      },
      {
        "name": "contract2",
        "path": "chaincode/contract2",
        "channels": [ "channel2" ],
        "init_args": [],
        "instantiate": false,
        "install": true
      }
    ]
  }
}
EOF

    mkdir -p "${testcase_gopath}/src/chaincode/contract1"
    mkdir -p "${testcase_gopath}/src/chaincode/contract2"

    cat << EOF > "${testcase_gopath}/src/chaincode/contract1/.govendor_packages"



       github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1     




  
EOF

     cat << EOF > "${testcase_gopath}/src/chaincode/contract2/.govendor_packages"



      github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1
      github.com/hyperledger/fabric/core/chaincode/lib/conga@v1.5.8   




  
EOF

    stub go \
        "get -u github.com/kardianos/govendor : true"

    stub govendor \
      "init : true" \
      "fetch *github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1* : true" \
      "init : true" \
      "fetch *github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1* : true" \
      "fetch *github.com/hyperledger/fabric/core/chaincode/lib/conga@v1.5.8* : true"

    stub cp \
      "-r vendor : true" \
      "-r vendor : true"

    source "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh"

    run fetch_dependencies "${testcase_gopath}/src/sample-config.json"
 
    # Assertions
    echo $output
    unstub cp
    unstub govendor
    unstub go
    [ $status -eq 0 ]  
    [ "${lines[0]}" = "Processing org 'org1'..." ]
    [ "${lines[1]}" = "About to fetch dependencies for 'chaincode/contract1'" ]
    [ "${lines[3]}" = "Found .govendor_packages file." ]
    [ "${lines[4]}" = "Fetching github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1" ]
    [ "${lines[7]}" = "Finished looking up dependencies for chaincode component." ]
    [ "${lines[8]}" = "About to fetch dependencies for 'chaincode/contract2'" ]
    [ "${lines[10]}" = "Found .govendor_packages file." ]
    [ "${lines[11]}" = "Fetching github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1" ]
    [ "${lines[12]}" = "Fetching github.com/hyperledger/fabric/core/chaincode/lib/conga@v1.5.8" ]
    [ "${lines[15]}" = "Finished looking up dependencies for chaincode component." ]
}

@test "vendor-dependencies.sh: fetch_dependencies should run without errors when .govendor_packages file does not end with a newline" {

    mkdir -p "${testcase_gopath}/src"
    cat << EOF > "${testcase_gopath}/src/sample-config.json"
{
  "org1": {
    "chaincode": [
      {
        "name": "contract1",
        "path": "chaincode/contract1",
        "channels": [ "channel1" ],
        "init_args": [],
        "instantiate": false,
        "install": true
      },
      {
        "name": "contract2",
        "path": "chaincode/contract2",
        "channels": [ "channel2" ],
        "init_args": [],
        "instantiate": false,
        "install": true
      }
    ]
  }
}
EOF

    mkdir -p "${testcase_gopath}/src/chaincode/contract2"

    echo -n "github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1" > "${testcase_gopath}/src/chaincode/contract2/.govendor_packages"

    stub go \
        "get -u github.com/kardianos/govendor : true"

    stub govendor \
      "init : true" \
      "fetch *github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1* : true"

    stub cp \
      "-r vendor : true"

    source "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh"

    run fetch_dependencies "${testcase_gopath}/src/sample-config.json"
 
    # Assertions
    echo $output
    unstub cp
    unstub govendor
    unstub go
    [ $status -eq 0 ]
    [ "${lines[0]}" = "Processing org 'org1'..." ]
    [ "${lines[1]}" = "About to fetch dependencies for 'chaincode/contract1'" ]
    [ "${lines[3]}" = "No .govendor_packages file found; no dependencies to vendor in." ]
    [ "${lines[6]}" = "About to fetch dependencies for 'chaincode/contract2'" ]
    [ "${lines[8]}" = "Found .govendor_packages file." ]
    [ "${lines[9]}" = "Fetching github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1" ]
}
