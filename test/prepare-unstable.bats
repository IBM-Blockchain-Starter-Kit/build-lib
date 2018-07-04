#!/usr/bin/env bats

load test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../src"
  testcase_dirname="$(mktemp -d)"

  export SCRIPT_DIR="${testcase_dirname}/script_dir/"
}

@test "prepare-unstable.sh: should exist and be executable" {
  [ -x "${src_dir}/prepare-unstable.sh" ]
}

@test "prepare-unstable.sh: should run without errors" {
  run "${src_dir}/prepare-unstable.sh"
  echo $output
  [ $status -eq 0 ]
}

@test "prepare-unstable.sh: should create SCRIPT_DIR if it does not exist already" {
  run "${src_dir}/prepare-unstable.sh"

  [ -d "${SCRIPT_DIR}" ]
}

@test "prepare-unstable.sh: should only create expected script files" {
  run "${src_dir}/prepare-unstable.sh"

  assert_build_scripts_exist "${src_dir}" "${SCRIPT_DIR}"
}

@test "prepare-unstable.sh: should not overwrite existing scripts in SCRIPT_DIR" {
  mkdir -p "${SCRIPT_DIR}"
  echo "DO NOT OVERWRITE" > "${SCRIPT_DIR}build.sh"

  run "${src_dir}/prepare-unstable.sh"

  cat "${SCRIPT_DIR}build.sh" | grep -Fxq 'DO NOT OVERWRITE'
}
