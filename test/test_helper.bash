#!/usr/bin/env bash

assert_build_scripts_exist() {
  src_dirname="$1"
  test_dirname="$2"
  
  diff -r --exclude prepare*.sh "$src_dirname" "$test_dirname"
}

setup_script_dir() {
  src_dirname="$1"
  test_dirname="$2"

  export SCRIPT_DIR="${test_dirname}/script_dir/"

  mkdir -p "${SCRIPT_DIR}"
  cp -a "${src_dirname}/"* "${SCRIPT_DIR}"
}

cleanup_stubs() {
  if stat ${BATS_TMPDIR}/*-stub-plan >/dev/null 2>&1; then
    for file in ${BATS_TMPDIR}/*-stub-plan; do
      program=$(basename $(echo "$file" | rev | cut -c 11- | rev))
      unstub $program || true
    done
  fi
}
