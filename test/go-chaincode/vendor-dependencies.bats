#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
    src_dir="${BATS_TEST_DIRNAME}/../../src"
    testcase_dirname="$(mktemp -d)"

    setup_script_dir "${src_dir}" "${testcase_dirname}"
}

@test "vendor-dependencies.sh: should exist and be executable" {
    [ -x "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh" ]
}

@test "vendor-dependencies.sh: fetch_dependencies should run without errors when .govendor_packages file does not exist" {

    cat << EOF > sample-config.json
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

    mkdir -p "${PWD}/src/chaincode/contract1"
    
    stub go \
        "get -u github.com/kardianos/govendor : true"

    source "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh"

    run fetch_dependencies "sample-config.json"

    # Clean up before assertions
    rm sample-config.json
    rm -rf "${PWD}/src/chaincode"
    unstub go
 
    # Assertions
    [ $status -eq 0 ]  
    [ "${lines[0]}" = "Processing org 'org1'..." ]
    [ "${lines[1]}" = "About to fetch dependencies for 'chaincode/contract1'" ]
    [ "${lines[3]}" = "No .govendor_packages file found; no dependencies to vendor in." ]

    [ "${lines[6]}" = "Processing org 'org2'..." ]
    [ "${lines[7]}" = "About to fetch dependencies for 'chaincode/contract1'" ]
    [ "${lines[9]}" = "No .govendor_packages file found; no dependencies to vendor in." ]  
}

@test "vendor-dependencies.sh: fetch_dependencies should run without errors when .govendor_packages file has new lines and white spaces" {

    cat << EOF > sample-config.json
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
  }
}
EOF

    mkdir -p "${PWD}/src/chaincode/contract1"

    cat << EOF > "${PWD}/src/chaincode/contract1/.govendor_packages"



       github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1     




  
EOF
    
    stub go \
        "get -u github.com/kardianos/govendor : true"

    stub govendor \
      "init : true"

    stub govendor \
       "fetch : true" 

    stub cp \
      "-r vendor : true"

    source "${SCRIPT_DIR}/go-chaincode/vendor-dependencies.sh"

    run fetch_dependencies "sample-config.json"

    # Clean up before assertions
    rm sample-config.json
    rm -rf "${PWD}/src/chaincode"
    unstub cp
    unstub govendor
    unstub go
 
    # Assertions
    echo $output
    [ $status -eq 0 ]  
    [ "${lines[0]}" = "Processing org 'org1'..." ]
    [ "${lines[1]}" = "About to fetch dependencies for 'chaincode/contract1'" ]
    [ "${lines[3]}" = "Found .govendor_packages file." ]
    [ "${lines[4]}" = "Fetching github.com/hyperledger/fabric/core/chaincode/lib/cid@v1.2.1" ]
    [ "${lines[7]}" = "Finished looking up dependencies for chaincode component." ]
}
