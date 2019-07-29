#!/usr/bin/env bash

#
# This pipeline script must be included directly in the pipeline yaml
# definition in order to fetch released versions of the common
# blockchain build scripts.
#
# See also: prepare-unstable.sh
#
# Alternatively, download and extract the scripts directly in the
# repository you are building. Once they are in your own repository you
# can modify them to suit your own build requirements.
#

#!/bin/bash
set -ex

if [ -n "$BUILD_LIB_URL" ]; then
  echo "=> Downloading Blockchain Build Libraries..."
  # download blockchain-build-lib
  build_lib_dir=$(mktemp -d)

  (curl -fsSL "$BUILD_LIB_URL") > "$build_lib_dir/blockchain-build-lib.tgz"

  mkdir -p "$SCRIPT_DIR"
  tar --keep-old-files -xvzf "$build_lib_dir/blockchain-build-lib.tgz" -C "$SCRIPT_DIR" > /dev/null 2>&1 || true
fi
if [ -n "$FABRIC_CLI_URL" ]; then
  echo "=> Downloading Fabric-CLI..."
  # download fabric-cli
  fabric_cli_dir=$(mktemp -d)

  (curl -fsSL "$FABRIC_CLI_URL") > "$fabric_cli_dir/fabric-cli.tgz"

  mkdir -p "$FABRIC_CLI_DIR"
  tar --keep-old-files -xvzf "$fabric_cli_dir/fabric-cli.tgz" -C "$FABRIC_CLI_DIR" > /dev/null 2>&1 || true
fi