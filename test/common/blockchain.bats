#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"
}

teardown() {
  cleanup_stubs
}

fill_blockchain_json() {
  cat << EOF > blockchain.json
{
  "org1": {
    "key": "key1",
    "secret": "secret1",
    "url": "url1",
    "network_id": "networkid1"
  },
  "org2": {
    "key": "key2",
    "secret": "secret2",
    "url": "url2",
    "network_id": "networkid2"
  }
}
EOF
}

cleanup_blockchain_json() {
  rm blockchain.json
}

@test "blockchain.sh: authenticate_org should grab the specified org's information" {
  skip

  source "${SCRIPT_DIR}/common/blockchain.sh"
  
  pushd "${SCRIPT_DIR}"

  fill_blockchain_json

  authenticate_org "org1"

  [ "$BLOCKCHAIN_KEY" = "key1" ]
  [ "$BLOCKCHAIN_SECRET" = "secret1" ]
  [ "$BLOCKCHAIN_API" = "url1/api/v1/networks/networkid1" ]

  authenticate_org "org2"

  [ "$BLOCKCHAIN_KEY" = "key2" ]
  [ "$BLOCKCHAIN_SECRET" = "secret2" ]
  [ "$BLOCKCHAIN_API" = "url2/api/v1/networks/networkid2" ]

  cleanup_blockchain_json
  popd
}

@test "blockchain.sh: provision_blockchain should populate 'blockchain.json' without an existing service instance and key" {
  skip

  stub cf \
    "create-service blockchain-service-name blockchain-service-plan blockchain-service-instance : echo 'Creating service instance...'" \
    "create-service-key blockchain-service-instance blockchain-service-key : echo 'Creating service key...'" \
    "service-key blockchain-service-instance blockchain-service-key : echo 'Getting key...'"

  stub tail "-n +2 : echo BLOCKCHAINJSON"
  
  export BLOCKCHAIN_SERVICE_INSTANCE="blockchain-service-instance"
  export BLOCKCHAIN_SERVICE_NAME="blockchain-service-name"
  export BLOCKCHAIN_SERVICE_PLAN="blockchain-service-plan"
  export BLOCKCHAIN_SERVICE_KEY="blockchain-service-key"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run provision_blockchain

  [ $status -eq 0 ]

  v=$(cat blockchain.json)
  [ "$v" = "BLOCKCHAINJSON" ]

  cleanup_blockchain_json

  unstub cf
  unstub tail
}

@test "blockchain.sh: provision_blockchain should exit 1 if service exists but is not a blockchain service" {
  skip

  stub cf \
    "create-service blockchain-service-name blockchain-service-plan blockchain-service-instance : echo 'The service instance name is taken...' && false"
  
  export BLOCKCHAIN_SERVICE_INSTANCE="blockchain-service-instance"
  export BLOCKCHAIN_SERVICE_NAME="blockchain-service-name"
  export BLOCKCHAIN_SERVICE_PLAN="blockchain-service-plan"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run provision_blockchain
  
  echo "$output"
  [ "${lines[1]}" = "Error creating blockchain service" ]
  [ $status -eq 1 ]

  unstub cf
}

@test "blockchain.sh: provision_blockchain should exit 1 if it fails to create service" {
  skip
  
  stub cf \
    "create-service blockchain-service-name blockchain-service-plan blockchain-service-instance : false"
  
  export BLOCKCHAIN_SERVICE_INSTANCE="blockchain-service-instance"
  export BLOCKCHAIN_SERVICE_NAME="blockchain-service-name"
  export BLOCKCHAIN_SERVICE_PLAN="blockchain-service-plan"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run provision_blockchain

  echo "$output"
  [ "${lines[0]}" = "Error creating blockchain service" ]
  [ $status -eq 1 ]

  unstub cf
}

@test "blockchain.sh: provision_blockchain should exit 1 if it fails to create service key" {
  skip
  
  stub cf \
    "create-service blockchain-service-name blockchain-service-plan blockchain-service-instance : exit 0" \
    "create-service-key blockchain-service-instance blockchain-service-key : exit 1"

  export BLOCKCHAIN_SERVICE_INSTANCE="blockchain-service-instance"
  export BLOCKCHAIN_SERVICE_NAME="blockchain-service-name"
  export BLOCKCHAIN_SERVICE_PLAN="blockchain-service-plan"
  export BLOCKCHAIN_SERVICE_KEY="blockchain-service-key"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run provision_blockchain

  echo "$output"
  [ "${lines[0]}" = "Error creating blockchain service key" ]
  [ $status -eq 1 ]

  unstub cf
}

@test "blockchain.sh: provision_blockchain should exit 1 if it fails to get the service key" {
  skip 
  
  stub cf \
    "create-service blockchain-service-name blockchain-service-plan blockchain-service-instance : echo 'Creating service instance...'" \
    "create-service-key blockchain-service-instance blockchain-service-key : echo 'Creating service key...'" \
    "service-key blockchain-service-instance blockchain-service-key : echo 'Could not get service key...' && false"

  export BLOCKCHAIN_SERVICE_NAME="blockchain-service-name"
  export BLOCKCHAIN_SERVICE_INSTANCE="blockchain-service-instance"
  export BLOCKCHAIN_SERVICE_KEY="blockchain-service-key"
  export BLOCKCHAIN_SERVICE_PLAN="blockchain-service-plan"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run provision_blockchain

  echo "$output"
  [ "${lines[2]}" = "Error retrieving blockchain service key" ]
  [ $status -eq 1 ]

  unstub cf
}

@test "blockchain.sh: setup_service_constants should export correct variables when region instance is ys1" {
  skip
  
  stub cut "echo ys1"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  setup_service_constants

  [ "${BLOCKCHAIN_SERVICE_NAME}" = "ibm-blockchain-5-staging" ]
  [ "${BLOCKCHAIN_SERVICE_PLAN}" = "ibm-blockchain-plan-v1-ga1-starter-staging" ]
  [ "${BLOCKCHAIN_SERVICE_KEY}" = "Credentials-1" ]

  unstub cut
}

@test "blockchain.sh: setup_service_constants should export correct variables when region instance is not ys1" {
  skip
  
  stub cut "echo test"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  setup_service_constants

  [ "${BLOCKCHAIN_SERVICE_NAME}" = "ibm-blockchain-5-prod" ]
  [ "${BLOCKCHAIN_SERVICE_PLAN}" = "ibm-blockchain-plan-v1-ga1-starter-prod" ]
  [ "${BLOCKCHAIN_SERVICE_KEY}" = "Credentials-1" ]

  unstub cut
}

@test "blockchain.sh: get_blockchain_connection_profile should properly run while loop" {
  skip
  
  echo "unset -f get_blockchain_connection_profile_inner" >> "${SCRIPT_DIR}/common/blockchain.sh"
  source "${SCRIPT_DIR}/common/blockchain.sh"

  stub sleep \
    "true" \
    "true"

  stub jq \
    "false" \
    "false" \
    "true"

  stub get_blockchain_connection_profile_inner \
    "true" \
    "echo test 1" \
    "echo test 2"

  run get_blockchain_connection_profile

  [ $status -eq 0 ]
  [ "${lines[0]}" = "test 1" ]
  [ "${lines[1]}" = "test 2" ]

  unstub jq
  unstub get_blockchain_connection_profile_inner
  unstub sleep
}

@test "blockchain.sh: get_blockchain_connection_profile_inner should call do_curl properly" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "true"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  run get_blockchain_connection_profile_inner

  [ $status -eq 0 ]

  rm blockchain-connection-profile.json

  unstub do_curl
}

@test "blockchain.sh: confirm_peer_status should return 0 if the peer has the expected status" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "-H Accept:?application/json -u test_key:test_secret https://blockchain.example.org/api/v1/networks/test_network/nodes/status : true"
  stub jq "--raw-output .\[\\\"peer1\\\"].status : echo running"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  BLOCKCHAIN_KEY=test_key \
    BLOCKCHAIN_SECRET=test_secret \
    BLOCKCHAIN_API=https://blockchain.example.org/api/v1/networks/test_network \
    run confirm_peer_status peer1 running

  echo "$output"
  [ $status -eq 0 ]

  unstub do_curl
  unstub jq
}

@test "blockchain.sh: confirm_peer_status should return 1 if the peer does not have the expected status" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "-H Accept:?application/json -u test_key:test_secret https://blockchain.example.org/api/v1/networks/test_network/nodes/status : true"
  stub jq "--raw-output .\[\\\"peer1\\\"].status : echo walking"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  
  BLOCKCHAIN_KEY=test_key \
    BLOCKCHAIN_SECRET=test_secret \
    BLOCKCHAIN_API=https://blockchain.example.org/api/v1/networks/test_network \
    run confirm_peer_status peer1 running

  echo "$output"
  [ $status -eq 1 ]

  unstub do_curl
  unstub jq
}

@test "blockchain.sh: confirm_peer_status should exit 1 if the peer status cannot be retrieved" {
  skip
  
  echo "unset -f do_curl" >> "${SCRIPT_DIR}/common/utils.sh"
  stub do_curl "-H Accept:?application/json -u test_key:test_secret https://blockchain.example.org/api/v1/networks/test_network/nodes/status : false"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  
  BLOCKCHAIN_KEY=test_key \
    BLOCKCHAIN_SECRET=test_secret \
    BLOCKCHAIN_API=https://blockchain.example.org/api/v1/networks/test_network \
    run confirm_peer_status peer1 running

  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "Error retrieving peer status" ]

  unstub do_curl
}

@test "blockchain.sh: confirm_peer_status should exit 1 if the peer status cannot be processed" {
  skip
  
  echo "unset -f do_curl" >> "${SCRIPT_DIR}/common/utils.sh"
  stub do_curl "-H Accept:?application/json -u test_key:test_secret https://blockchain.example.org/api/v1/networks/test_network/nodes/status : true"
  stub jq "--raw-output .\[\\\"peer1\\\"].status : echo walking && false"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  
  BLOCKCHAIN_KEY=test_key \
    BLOCKCHAIN_SECRET=test_secret \
    BLOCKCHAIN_API=https://blockchain.example.org/api/v1/networks/test_network \
    run confirm_peer_status peer1 running

  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[0]}" = "Error processing peer status" ]

  unstub do_curl
}

@test "blockchain.sh: start_blockchain_peer should post to start URL and wait for peer to start" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl \
    "-X POST -H Accept:?application/json -u test_key:test_secret https://blockchain.example.org/api/v1/networks/test_network/nodes/peer1/start : true"
  stub retry_with_backoff \
    "5 confirm_peer_status peer1 running : true"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  BLOCKCHAIN_KEY=test_key \
    BLOCKCHAIN_SECRET=test_secret \
    BLOCKCHAIN_API=https://blockchain.example.org/api/v1/networks/test_network \
    run start_blockchain_peer peer1

  echo "$output"
  [ $status -eq 0 ]

  unstub do_curl
  unstub retry_with_backoff
}

@test "blockchain.sh: stop_blockchain_peer should post to stop URL and wait for peer to stop" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl \
    "-X POST -H Accept:?application/json -u test_key:test_secret https://blockchain.example.org/api/v1/networks/test_network/nodes/peer1/stop : true"
  stub retry_with_backoff \
    "5 confirm_peer_status peer1 exited : true"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  BLOCKCHAIN_KEY=test_key \
    BLOCKCHAIN_SECRET=test_secret \
    BLOCKCHAIN_API=https://blockchain.example.org/api/v1/networks/test_network \
    run stop_blockchain_peer peer1

  echo "$output"
  [ $status -eq 0 ]

  unstub do_curl
  unstub retry_with_backoff
}

@test "blockchain.sh: restart_blockchain_peer stop and start a peer" {
  skip
  
  echo "unset -f stop_blockchain_peer" >> "${SCRIPT_DIR}/common/blockchain.sh"
  echo "unset -f start_blockchain_peer" >> "${SCRIPT_DIR}/common/blockchain.sh"

  stub stop_blockchain_peer "peer1 : true"
  stub start_blockchain_peer "peer1 : true"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run restart_blockchain_peer peer1

  echo "$output"
  [ $status -eq 0 ]

  unstub stop_blockchain_peer
  unstub start_blockchain_peer
}

@test "blockchain.sh: install_fabric_chaincode should return status 0 if fabric chaincode is successfully installed" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "exit 0"
  stub zip "echo ZIP file created!"
      
  source "${SCRIPT_DIR}/common/blockchain.sh"
  CCPATH=$(pwd)
  run install_fabric_chaincode "ccid" "ccversion" "$CCPATH"

  [ "${lines[5]}" = "Successfully installed fabric contract." ]
  [ $status -eq 0 ]

  unstub zip
  unstub do_curl
}

@test "blockchain.sh: install_fabric_chaincode should return status 1 if unrecognized error is received" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  error_msg="error"

  stub do_curl "echo ${error_msg}; exit 1"
  stub zip "echo ZIP file created!"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  CCPATH=$(pwd)
  run install_fabric_chaincode "ccid" "ccversion" "$CCPATH"

  [ "${lines[5]}" = "Failed to install fabric contract:" ]
  [ "${lines[6]}" = "Unrecognized error returned:" ]
  [ "${lines[7]}" = "${error_msg}" ]
  [ $status -eq 1 ]

  unstub zip
  unstub do_curl
}

@test "blockchain.sh: install_fabric_chaincode should return status 2 if already installed with specified version and id" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "echo chaincode code exists; exit 1"
  stub zip "echo ZIP file created!"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  CCPATH=$(pwd)
  run install_fabric_chaincode "ccid" "ccversion" "$CCPATH"

  [ "${lines[5]}" = "Failed to install fabric contract:" ]
  [ "${lines[6]}" = "Chaincode already installed with id 'ccid' and version 'ccversion'" ]
  [ $status -eq 2 ]

  unstub zip
  unstub do_curl
}

@test "blockchain.sh: instantiate_fabric_chaincode should return status 0 upon success response from request" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "exit 0"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "type" "channel" '"arg1", "arg2"'

  echo "$output"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' version 'version' and chaincode type 'type' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Successfully instantiated fabric contract." ]

  unstub do_curl
}

@test "blockchain.sh: instantiate_fabric_chaincode should retry after connection problems" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl \
    "echo foobar_Failed to establish a backside connection_foobar; exit 1" \
    "exit 0"
  stub sleep "30 : true"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "type" "channel" '"arg1", "arg2"'

  [ $status -eq 0 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' version 'version' and chaincode type 'type' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Connection problem encountered, delaying 30s and trying again..." ]
  [ "${lines[2]}" = "Instantiating fabric contract with id 'id' version 'version' and chaincode type 'type' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[3]}" = "Successfully instantiated fabric contract." ]

  unstub do_curl
  unstub sleep
}

@test "blockchain.sh: instantiate_fabric_chaincode should fail on existing version response" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl \
    "echo foobar_version already exists for chaincode_foobar; exit 1"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "type" "channel" '"arg1", "arg2"'
  [ $status -eq 2 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' version 'version' and chaincode type 'type' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Failed to instantiate fabric contract:" ]
  [ "${lines[2]}" = "Chaincode instance already exists with id 'id' version 'version' and chaincode type 'type'" ]
}

@test "blockchain.sh: instantiate_fabric_chaincode should fail on unknown error response" {
  skip
  
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  error_msg="UNKNOWN ERROR"

  stub do_curl \
    "echo ${error_msg}; exit 1"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "type" "channel" '"arg1", "arg2"'

  [ $status -eq 1 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' version 'version' and chaincode type 'type' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Failed to instantiate fabric contract:" ]
  [ "${lines[2]}" = "Unrecognized error returned:" ]
  [ "${lines[3]}" = "${error_msg}" ]
}

@test "blockchain.sh: deploy_fabric_chaincode should iterate through provided organizations and authenticate" {
  skip
  
  cat << EOF > sample-config.json
{
  "org1": {},
  "org2": {}
}
EOF

  echo "unset -f authenticate_org" >> "${SCRIPT_DIR}/common/blockchain.sh"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  stub authenticate_org \
    "org1 : echo AUTH1" \
    "org2 : echo AUTH2"

  run deploy_fabric_chaincode "type" "sample-config.json"

  echo "$output"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "Parsing deployment configuration:" ]
  [ "${lines[5]}" = "Targeting org 'org1'..." ]
  [ "${lines[6]}" = "AUTH1" ]
  [ "${lines[8]}" = "Targeting org 'org2'..." ]
  [ "${lines[9]}" = "AUTH2" ]
  [ "${lines[11]}" = "Done parsing deployment configuration." ]

  rm sample-config.json

  unstub authenticate_org
}

@test "blockchain.sh: deploy_fabric_chaincode should make appropriate calls to install/instantiate bsaed on an org config" {
  skip
  
  cat << EOF > sample-config.json
{
  "org1": {
        "chaincode": [
            {
                "name": "contract1",
                "path": "src/chaincode",
                "channels": [ "channel1" ],
                "init_args": [],
                "instantiate": false,
                "install": false
            },
            {
                "name": "contract2",
                "path": "lib/chaincode",
                "channels": [ "channel2" ],
                "init_args": [],
                "instantiate": true,
                "install": true
            }
        ]
    }
}
EOF

  echo "unset -f authenticate_org" >> "${SCRIPT_DIR}/common/blockchain.sh"
  echo "unset -f install_fabric_chaincode" >> "${SCRIPT_DIR}/common/blockchain.sh"
  echo "unset -f instantiate_fabric_chaincode" >> "${SCRIPT_DIR}/common/blockchain.sh"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  stub authenticate_org "org1 : true"
  stub date "echo 20180821105050"
  stub install_fabric_chaincode "contract2 20180821105050-8 lib/chaincode type : true"
  stub instantiate_fabric_chaincode "contract2 20180821105050-8 type channel2 : true"

  BUILD_NUMBER=8 \
    run deploy_fabric_chaincode "type" "sample-config.json"

  echo "$output"
  [ $status -eq 0 ]
  [ "${lines[0]}" = "Parsing deployment configuration:" ]
  [ "${lines[23]}" = "Targeting org 'org1'..." ]
  [ "${lines[24]}" = "Done parsing deployment configuration." ]

  rm sample-config.json

  unstub date
  unstub authenticate_org
  unstub install_fabric_chaincode
  unstub instantiate_fabric_chaincode
}

@test "blockchain.sh: deploy_fabric_chaincode should install the same chaincode version for every org" {
  skip
  
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

  echo "unset -f authenticate_org" >> "${SCRIPT_DIR}/common/blockchain.sh"
  echo "unset -f install_fabric_chaincode" >> "${SCRIPT_DIR}/common/blockchain.sh"
  echo "unset -f instantiate_fabric_chaincode" >> "${SCRIPT_DIR}/common/blockchain.sh"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  stub authenticate_org \
    "org1 : true" \
    "org2 : true"
  stub date "echo 20180821105050"
  stub install_fabric_chaincode \
    "contract1 20180821105050-8 chaincode/contract1 type : true" \
    "contract1 20180821105050-8 chaincode/contract1 type : true"

  BUILD_NUMBER=8 \
    run deploy_fabric_chaincode "type" "sample-config.json"

  echo "$output"
  [ $status -eq 0 ]

  rm sample-config.json

  unstub date
  unstub authenticate_org
  unstub install_fabric_chaincode
}
