#!/usr/bin/env bash
#
# Cloudant database helper functions.

# shellcheck source=src/common/utils.sh
source "${SCRIPT_DIR}/common/utils.sh"

export CLOUDANT_SERVICE_NAME=cloudantNoSQLDB
export CLOUDANT_SERVICE_PLAN=Lite
export CLOUDANT_SERVICE_KEY=Credentials-1
export CLOUDANT_DATABASE=wallet

#######################################
# Provision a new Cloudant service instance if one does not already exist
# Globals:
#   CLOUDANT_SERVICE_INSTANCE
#   CLOUDANT_SERVICE_NAME
#   CLOUDANT_SERVICE_PLAN
#   CLOUDANT_SERVICE_KEY
#   CLOUDANT_DATABASE
# Arguments:
#   None
# Returns:
#   None
#######################################
function provision_cloudant {
  # Creating a service and service key for an existing cloudant service does not fail
  cf create-service "${CLOUDANT_SERVICE_NAME}" "${CLOUDANT_SERVICE_PLAN}" "${CLOUDANT_SERVICE_INSTANCE}" || error_exit "Error creating cloudant service"
  cf create-service-key "${CLOUDANT_SERVICE_INSTANCE}" "${CLOUDANT_SERVICE_KEY}" || error_exit "Error creating cloudant service key"

  local cloudant_service_key
  cloudant_service_key=$(cf service-key "${CLOUDANT_SERVICE_INSTANCE}" "${CLOUDANT_SERVICE_KEY}") || error_exit "Error retrieving cloudant service key"

  CLOUDANT_CREDS=$(echo "${cloudant_service_key}" | tail -n +2 | jq ". + {database: \"${CLOUDANT_DATABASE}\"}") || error_exit "Error configuring cloudant service credentials"
  export CLOUDANT_CREDS

  CLOUDANT_URL=$(echo "${CLOUDANT_CREDS}" | jq --raw-output '.url') || error_exit "Error extracting cloudant URL"
  export CLOUDANT_URL
}

#######################################
# Create a new Cloudant database if one does not already exist
# Globals:
#   CLOUDANT_URL
#   CLOUDANT_DATABASE
# Arguments:
#   None
# Returns:
#   None
#######################################
function create_cloudant_database {
  if ! do_curl "${CLOUDANT_URL}/${CLOUDANT_DATABASE}" > /dev/null 2>&1
  then
    do_curl -X PUT "${CLOUDANT_URL}/${CLOUDANT_DATABASE}"
  fi
}
