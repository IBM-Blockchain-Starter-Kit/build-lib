#!/usr/bin/env bash

function assert_build_scripts_exist {
  src_dirname="$1"
  test_dirname="$2"
  
  diff -r --exclude prepare-*.sh "$src_dirname" "$test_dirname"
}
