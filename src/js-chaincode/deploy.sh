#!/usr/bin/env bash

# JS chaincode specific deploy script

# shellcheck source=src/common/deploy.sh
source "${SCRIPT_DIR}/common/deploy.sh"

$DEBUG && set -x

deploy_cc "node" "${CC_REPO_DIR}"