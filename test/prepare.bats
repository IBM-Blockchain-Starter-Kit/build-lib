#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../bats-mock/stub.bash"
load test_helper

setup() {
  src_dir="${BATS_TEST_DIRNAME}/../src"
  testcase_dirname="$(mktemp -d)"

  export SCRIPT_URL="https://example.org/scripts"
  export SCRIPT_DIR="${testcase_dirname}/script_dir"
}

teardown() {
  cleanup_stubs
}

stub_curl() {
  stub curl "-fsSL https://example.org/toolchain-script-lib.tgz : tar --exclude prepare*.sh -C ${src_dir} -cvzf - ."
}

@test "prepare.sh: should exist and be executable" {
  [ -x "${src_dir}/prepare.sh" ]
}

@test "prepare.sh: should not attempt to fetch scripts if BUILD_LIB_URL is not set" {
  stub curl "true"

  run ${src_dir}/prepare.sh

  echo $output
  [ $status -eq 0 ]

  [ ! -e ${SCRIPT_DIR} ]

  unstub curl || true
}

@test "prepare.sh: should fetch scripts from BUILD_LIB_URL" {
  stub curl "true"

  BUILD_LIB_URL='https://example.org/toolchain-script-lib.tgz' \
    run ${src_dir}/prepare.sh

  echo $output
  [ $status -eq 0 ]

  ls -al ${SCRIPT_DIR}

  # assert_build_scripts_exist "${src_dir}" "${SCRIPT_DIR}"

  unstub curl
}

@test "prepare.sh: should not overwrite existing scripts in SCRIPT_DIR" {
  stub_curl

  mkdir -p "${SCRIPT_DIR}"
  echo "DO NOT OVERWRITE" > "${SCRIPT_DIR}/router.sh"

  BUILD_LIB_URL='https://example.org/toolchain-script-lib.tgz' \
    run ${src_dir}/prepare.sh

  head -n 1 "${SCRIPT_DIR}/router.sh"
  cat "${SCRIPT_DIR}/router.sh" | grep -Fxq 'DO NOT OVERWRITE'

  unstub curl
}

@test "prepare.sh: should fail tarball cannot be fetched from BUILD_LIB_URL" {
  BUILD_LIB_URL='https://example.org/toolchain-script-lib.tgz' \
    run ${src_dir}/prepare.sh

  echo "status = $status"
  echo $output
  [ $status -eq 22 ]
}
