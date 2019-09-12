#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../bats-mock/stub.bash"
load ../test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../../src"
  testcase_dirname="$(mktemp -d)"

  setup_script_dir "${src_dir}" "${testcase_dirname}"

  echo "unset -f do_curl" >> "${SCRIPT_DIR}/common/utils.sh"

  unset CLOUDANT_SERVICE_INSTANCE
  unset CLOUDANT_SERVICE_NAME
  unset CLOUDANT_SERVICE_PLAN
  unset CLOUDANT_SERVICE_KEY
  unset CLOUDANT_DATABASE
  unset CLOUDANT_URL

  source "${SCRIPT_DIR}/common/cloudant.sh"
}

teardown() {
  cleanup_stubs
}

@test "cloudant.sh: provision_cloudant should provision a new cloudant sevice and create a service key if the service does not already exist" {
  skip

  stub cf \
    "create-service cloudantNoSQLDB Lite cloudant-service-instance : echo 'Creating service instance...'" \
    "create-service-key cloudant-service-instance Credentials-1 : echo 'Creating service key...'" \
    "service-key cloudant-service-instance Credentials-1 : echo 'Getting key...'"

  stub jq \
    "*mydb* : echo CLOUDANT_CREDS_VALUE" \
    "--raw-output .url : echo CLOUDANT_URL_VALUE"
  
  CLOUDANT_DATABASE="mydb" \
    CLOUDANT_SERVICE_INSTANCE="cloudant-service-instance" \
    run provision_cloudant

  echo "$output"
  [ $status -eq 0 ]

  unstub cf
  unstub jq
}

@test "cloudant.sh: provision_cloudant should exit 1 if service exists but is not a cloudant service" {
  skip
  
  stub cf \
    "create-service cloudantNoSQLDB Lite cloudant-service-instance : echo 'The service instance name is taken...' && false"
  
  CLOUDANT_DATABASE="mydb" \
    CLOUDANT_SERVICE_INSTANCE="cloudant-service-instance" \
    run provision_cloudant

  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[1]}" = "Error creating cloudant service" ]

  unstub cf
}

@test "cloudant.sh: provision_cloudant should exit 1 if the create service key command fails" {
  skip
  
  stub cf \
    "create-service cloudantNoSQLDB Lite cloudant-service-instance : echo 'Creating service instance...'" \
    "create-service-key cloudant-service-instance Credentials-1 : echo 'Could not create service key...' && false"
  
  CLOUDANT_DATABASE="mydb" \
    CLOUDANT_SERVICE_INSTANCE="cloudant-service-instance" \
    run provision_cloudant

  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[2]}" = "Error creating cloudant service key" ]

  unstub cf
}

@test "cloudant.sh: provision_cloudant should exit 1 if the service key command fails" {
  skip
  
  stub cf \
    "create-service cloudantNoSQLDB Lite cloudant-service-instance : echo 'Creating service instance...'" \
    "create-service-key cloudant-service-instance Credentials-1 : echo 'Creating service key...'" \
    "service-key cloudant-service-instance Credentials-1 : echo 'Could not get service key...' && false"
  
  CLOUDANT_DATABASE="mydb" \
    CLOUDANT_SERVICE_INSTANCE="cloudant-service-instance" \
    run provision_cloudant

  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[2]}" = "Error retrieving cloudant service key" ]

  unstub cf
}

@test "cloudant.sh: provision_cloudant should exit 1 if the CLOUDANT_CREDS variable cannot be created" {
  skip

  stub cf \
    "create-service cloudantNoSQLDB Lite cloudant-service-instance : echo 'Creating service instance...'" \
    "create-service-key cloudant-service-instance Credentials-1 : echo 'Creating service key...'" \
    "service-key cloudant-service-instance Credentials-1 : echo 'Getting key...'"

  stub jq \
    "*mydb* : echo 'Invalid JSON...' && false"
  
  CLOUDANT_DATABASE="mydb" \
    CLOUDANT_SERVICE_INSTANCE="cloudant-service-instance" \
    run provision_cloudant

  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[2]}" = "Error configuring cloudant service credentials" ]

  unstub cf
  unstub jq
}

@test "cloudant.sh: provision_cloudant should exit 1 if the CLOUDANT_URL variable cannot be created" {
  skip

  stub cf \
    "create-service cloudantNoSQLDB Lite cloudant-service-instance : echo 'Creating service instance...'" \
    "create-service-key cloudant-service-instance Credentials-1 : echo 'Creating service key...'" \
    "service-key cloudant-service-instance Credentials-1 : echo 'Getting key...'"

  stub jq \
    "*mydb* : echo CLOUDANT_CREDS_VALUE" \
    "--raw-output .url : echo 'Invalid JSON...' && false"
  
  CLOUDANT_DATABASE="mydb" \
    CLOUDANT_SERVICE_INSTANCE="cloudant-service-instance" \
    run provision_cloudant

  echo "$output"
  [ $status -eq 1 ]
  [ "${lines[2]}" = "Error extracting cloudant URL" ]

  unstub cf
  unstub jq
}

@test "cloudant.sh: create_cloudant_database should create a new database if it does not already exist" {
  skip
  
  stub do_curl \
    "https://cloudant.example.org/TestDatabase : false" \
    "-X PUT https://cloudant.example.org/TestDatabase : true"

  CLOUDANT_URL="https://cloudant.example.org" \
    CLOUDANT_DATABASE="TestDatabase" \
    run create_cloudant_database

  echo "$output"
  [ $status -eq 0 ]

  unstub do_curl
}

@test "cloudant.sh: create_cloudant_database should not create a new database if it already exists" {
  skip
  
  stub do_curl "https://cloudant.example.org/TestDatabase : true"

  CLOUDANT_URL="https://cloudant.example.org" \
    CLOUDANT_DATABASE="TestDatabase" \
    run create_cloudant_database

  echo "$output"
  [ $status -eq 0 ]

  unstub do_curl
}
