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

@test "deploy.sh: should exist and be executable" {
    [ -x "${SCRIPT_DIR}/go-chaincode/deploy.sh" ]
}

@test "deploy.sh: should fail if deploy configuration does not exist" {
    export CONFIGPATH="fakepath"

     stub go \
        "get -u github.com/kardianos/govendor : true"

    run "${SCRIPT_DIR}/go-chaincode/deploy.sh"

    [ "${lines[0]}" = "No deploy configuration at specified path: fakepath" ]
    [ $status -eq 1 ]
}

@test "deploy.sh: should succeed if deploy configuration exists" {
    export CONFIGPATH=$(mktemp)

    echo "true" > "${SCRIPT_DIR}/common/env.sh"
    echo "unset -f nvm_install_node" >> "${SCRIPT_DIR}/common/utils.sh"
    echo "unset -f build_fabric_cli" >> "${SCRIPT_DIR}/common/utils.sh"
    echo "unset -f install_jq" >> "${SCRIPT_DIR}/common/utils.sh"

    source "${SCRIPT_DIR}/common/env.sh"
    source "${SCRIPT_DIR}/common/utils.sh"

    stub nvm_install_node "8.16.0 : true"
    stub build_fabric_cli "true"
    stub install_jq "true"

    stub mkdir "true"

    export ADMIN_IDENTITY_STRING="{}"
    export CONNECTION_PROFILE_STRING="{}"

    export NODE_VERSION="8.16.0"
    export FABRIC_CLI_DIR="fabric-cli"
    run ${SCRIPT_DIR}/go-chaincode/deploy.sh
    
    [ $status -eq 0 ]

    unstub nvm_install_node
    unstub build_fabric_cli
    unstub install_jq
}
