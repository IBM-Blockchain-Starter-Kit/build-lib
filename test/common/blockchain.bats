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
	stub cf \
		"service bsi : exit 1" \
		"create-service bsn bsp bsi : exit 0" \
		"service-key bsi bsk : exit 1" \
		"create-service-key bsi bsk : exit 0" \
		"service-key bsi bsk : true"

	stub tail "-n +2 : echo BLOCKCHAINJSON"
  
  export BLOCKCHAIN_SERVICE_INSTANCE="bsi"
	export BLOCKCHAIN_SERVICE_NAME="bsn"
	export BLOCKCHAIN_SERVICE_PLAN="bsp"
	export BLOCKCHAIN_SERVICE_KEY="bsk"

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
	stub cf "service bsi : echo Name: Blockchain-m5 Service: test tags: Plan: ibm-blockchain-plan-v1-ga1-starter-prod"
  
  export BLOCKCHAIN_SERVICE_INSTANCE="bsi"
  export BLOCKCHAIN_SERVICE_NAME="bsn"

  source "${SCRIPT_DIR}/common/blockchain.sh"

	run provision_blockchain
  
  [ "${lines[0]}" = "Service with the provided name exists, but it is not a blockchain service." ]
	[ $status -eq 1 ]

	unstub cf
}

@test "blockchain.sh: provision_blockchain should exit 1 if it fails to create service" {
	stub cf \
		"service bsi : exit 1" \
		"create-service bsn bsp bsi : exit 1"
  
  export BLOCKCHAIN_SERVICE_INSTANCE="bsi"
	export BLOCKCHAIN_SERVICE_NAME="bsn"
	export BLOCKCHAIN_SERVICE_PLAN="bsp"

  source "${SCRIPT_DIR}/common/blockchain.sh"

	run provision_blockchain

  [ "${lines[0]}" = "Failed to create service." ]
	[ $status -eq 1 ]

	unstub cf
}

@test "blockchain.sh: provision_blockchain should exit 1 if it fails to create service key" {
	stub cf \
		"service bsi : exit 1" \
		"create-service bsn bsp bsi : exit 0" \
		"service-key bsi bsk : exit 1" \
		"create-service-key bsi bsk : exit 1"

  export BLOCKCHAIN_SERVICE_INSTANCE="bsi"
	export BLOCKCHAIN_SERVICE_NAME="bsn"
	export BLOCKCHAIN_SERVICE_PLAN="bsp"
	export BLOCKCHAIN_SERVICE_KEY="bsk"

  source "${SCRIPT_DIR}/common/blockchain.sh"

	run provision_blockchain

  [ "${lines[0]}" = "Failed to create service key." ]
	[ $status -eq 1 ]

	unstub cf
}

@test "blockchain.sh: provision_blockchain should populate 'blockchain.json' using an existing service instance and key" {
	stub cf \
		"service bsi : echo Name: Blockchain-m5 Service: bsn tags: Plan: ibm-blockchain-plan-v1-ga1-starter-prod" \
		"service-key bsi bsk : exit 0" \
		"service-key bsi bsk : true"

	stub tail "-n +2 : echo BLOCKCHAINJSON"
  
  export BLOCKCHAIN_SERVICE_NAME="bsn"
  export BLOCKCHAIN_SERVICE_INSTANCE="bsi"
	export BLOCKCHAIN_SERVICE_KEY="bsk"

  source "${SCRIPT_DIR}/common/blockchain.sh"

	run provision_blockchain
  [ $status -eq 0 ]

	v=$(cat blockchain.json)
	[ "$v" = "BLOCKCHAINJSON" ]

	cleanup_blockchain_json

	unstub cf
	unstub tail
}

@test "blockchain.sh: setup_service_constants should export correct variables when region instance is ys1" {
  stub cut "echo ys1"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  setup_service_constants

  [ "${BLOCKCHAIN_SERVICE_NAME}" = "ibm-blockchain-5-staging" ]
  [ "${BLOCKCHAIN_SERVICE_PLAN}" = "ibm-blockchain-plan-v1-ga1-starter-staging" ]
  [ "${BLOCKCHAIN_SERVICE_KEY}" = "Credentials-1" ]

  unstub cut
}

@test "blockchain.sh: setup_service_constants should export correct variables when region instance is not ys1" {
  stub cut "echo test"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  setup_service_constants

  [ "${BLOCKCHAIN_SERVICE_NAME}" = "ibm-blockchain-5-prod" ]
  [ "${BLOCKCHAIN_SERVICE_PLAN}" = "ibm-blockchain-plan-v1-ga1-starter-prod" ]
  [ "${BLOCKCHAIN_SERVICE_KEY}" = "Credentials-1" ]

  unstub cut
}

@test "blockchain.sh: get_blockchain_connection_profile should properly run while loop" {
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
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "true"

	source "${SCRIPT_DIR}/common/blockchain.sh"
  run get_blockchain_connection_profile_inner

  [ $status -eq 0 ]

  rm blockchain-connection-profile.json

  unstub do_curl
}

@test "blockchain.sh: install_fabric_chaincode should return status 0 if fabric chaincode is successfully installed" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "exit 0"
  stub find "echo contract.go"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  run install_fabric_chaincode "ccid" "ccversion" "ccpath"

  [ "${lines[1]}" = "Successfully installed fabric contract." ]
  [ $status -eq 0 ]

  unstub do_curl
  unstub find
}

@test "blockchain.sh: install_fabric_chaincode should return status 1 if unrecognized error is received" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  error_msg="error"

  stub do_curl "echo ${error_msg}; exit 1"
  stub find "echo contract.go"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  run install_fabric_chaincode "ccid" "ccversion" "ccpath"

  [ "${lines[1]}" = "Failed to install fabric contract:" ]
  [ "${lines[2]}" = "Unrecognized error returned:" ]
  [ "${lines[3]}" = "${error_msg}" ]
  [ $status -eq 1 ]

  unstub do_curl
  unstub find
}

@test "blockchain.sh: install_fabric_chaincode should return status 2 if already installed with specified version and id" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "echo chaincode code exists; exit 1"
  stub find "echo contract.go"

  source "${SCRIPT_DIR}/common/blockchain.sh"
  run install_fabric_chaincode "ccid" "ccversion" "ccpath"

  [ "${lines[1]}" = "Failed to install fabric contract:" ]
  [ "${lines[2]}" = "Chaincode already installed with id 'ccid' and version 'ccversion'" ]
  [ $status -eq 2 ]

  unstub do_curl
  unstub find
}

@test "blockchain.sh: install_fabric_chaincode should correctly build array of files from directory path" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "exit 0"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  pushd "${SCRIPT_DIR}/.."
  mkdir -p "cc/path"
  touch "cc/path/contract.go"
  touch "cc/path/contract_test.go"
  touch "cc/path/notchaincode.txt"

  install_fabric_chaincode "ccid" "ccversion" "cc/path"
  popd

  [[ "${CHAINCODE_FILE_OPTS}" == ?"-F files[]=@cc/path/notchaincode.txt -F files[]=@cc/path/contract.go" ]] || \
  [[ "${CHAINCODE_FILE_OPTS}" == ?"-F files[]=@cc/path/contract.go -F files[]=@cc/path/notchaincode.txt" ]]

  unstub do_curl
}

@test "blockchain.sh: instantiate_fabric_chaincode should return status 0 upon success response from request" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl "exit 0"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "channel" '"arg1", "arg2"'
  [ $status -eq 0 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' and version 'version' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Successfully instantiated fabric contract." ]

  unstub do_curl
}

@test "blockchain.sh: instantiate_fabric_chaincode should retry after connection problems" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl \
    "echo foobar_Failed to establish a backside connection_foobar; exit 1" \
    "exit 0"
  stub sleep "30 : true"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "channel" '"arg1", "arg2"'

  [ $status -eq 0 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' and version 'version' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Connection problem encountered, delaying 30s and trying again..." ]
  [ "${lines[2]}" = "Instantiating fabric contract with id 'id' and version 'version' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[3]}" = "Successfully instantiated fabric contract." ]

  unstub do_curl
  unstub sleep
}

@test "blockchain.sh: instantiate_fabric_chaincode should fail on existing version response" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  stub do_curl \
    "echo foobar_version already exists for chaincode_foobar; exit 1"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "channel" '"arg1", "arg2"'
  [ $status -eq 2 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' and version 'version' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Failed to instantiate fabric contract:" ]
  [ "${lines[2]}" = "Chaincode instance already exists with id 'id' and version 'version'" ]
}

@test "blockchain.sh: instantiate_fabric_chaincode should fail on unknown error response" {
  echo "true" > "${SCRIPT_DIR}/common/utils.sh"

  error_msg="UNKNOWN ERROR"

  stub do_curl \
    "echo ${error_msg}; exit 1"

  source "${SCRIPT_DIR}/common/blockchain.sh"

  run instantiate_fabric_chaincode "id" "version" "channel" '"arg1", "arg2"'

  [ $status -eq 1 ]
  [ "${lines[0]}" = "Instantiating fabric contract with id 'id' and version 'version' on channel 'channel' with arguments '\"arg1\", \"arg2\"'..." ]
  [ "${lines[1]}" = "Failed to instantiate fabric contract:" ]
  [ "${lines[2]}" = "Unrecognized error returned:" ]
  [ "${lines[3]}" = "${error_msg}" ]
}

@test "blockchain.sh: deploy_fabric_chaincode should iterate through provided organizations and authenticate" {
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

  run deploy_fabric_chaincode "sample-config.json"

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
  stub date \
    "echo v100" \
    "echo v200"
  stub install_fabric_chaincode "contract2 v200- lib/chaincode : true"
  stub instantiate_fabric_chaincode "contract2 v200- channel2 : true"

  run deploy_fabric_chaincode "sample-config.json"

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