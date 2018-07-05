#!/usr/bin/env bash

assert_build_scripts_exist() {
  src_dirname="$1"
  test_dirname="$2"
  
  diff -r --exclude prepare-*.sh "$src_dirname" "$test_dirname"
}

setup_script_dir() {
  export SCRIPT_DIR="${2}/script_dir/"

  mkdir -p "${SCRIPT_DIR}"
  cp -a "${1}/"* "${SCRIPT_DIR}"
}
