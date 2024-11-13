#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "tmpfile.bash"
  __BG_ERR_FORMAT='%s\n'
}

test_tmpfile.new_fails_when_filename_var_is_not_a_valid_var_name() {
  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2016
  bg.tmpfile.new '$myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "return code should be 1 filename_var is not a valid var name"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "'\$myvar' is not a valid variable name" "$(< "$stderr_file")"
}


test_tmpfile.new_creates_two_temporary_files() {
  ./test_scripts/tmpfile.bash
}

test_tmpfile.new_invokes_mktemp_and_trap_function() {
  set -euo pipefail
  local stdout_file
  local stderr_file
  local tmpfile_name_file
  local trap_output_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  trap_output_file="$(mktemp)"
  tmpfile_name_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file" "$tmpfile_name_file" "$trap_output_file"

  fake_mktemp() {
    echo "test_file" >"$tmpfile_name_file"
    cat "$tmpfile_name_file"
  }

  bg.trap.add() {
    echo "1:$1" >"$trap_output_file"
    echo "2:$2" >>"$trap_output_file"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals \
    "$(printf "%s\n%s" "1:rm -f '$(< "$tmpfile_name_file")'" "2:EXIT")" \
    "$(< "$trap_output_file")"
  assert_equals "$(< "$tmpfile_name_file")" "$filename" "'filename' var should contain name of temp file"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0"
}


test_tmpfile.new_stores_tmpfilen_name_in_var_even_when_var_is_not_defined_beforehand() {
  set -euo pipefail
  local stdout_file
  local stderr_file
  local tmpfile_name_file
  local trap_output_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  trap_output_file="$(mktemp)"
  tmpfile_name_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file" "$tmpfile_name_file" "$trap_output_file"

  fake_mktemp() {
    echo "test_file" >"$tmpfile_name_file"
    cat "$tmpfile_name_file"
  }

  bg.trap.add() {
    echo "1:$1" >"$trap_output_file"
    echo "2:$2" >>"$trap_output_file"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'myfilename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals \
    "$(printf "%s\n%s" "1:rm -f '$(< "$tmpfile_name_file")'" "2:EXIT")" \
    "$(< "$trap_output_file")"
  assert_equals "$(< "$tmpfile_name_file")" "$myfilename" "'myfilename' var should contain name of temp file"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0"
}


test_tmpfile.new_returns_1_if_mktemp_fails() {
  local stdout_file
  local stderr_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file"

  fake_mktemp() {
    return 1
  }

  bg.trap.add() {
    echo "1:${1:-}"
    echo "2:${2:-}"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "${filename:-}" "'filename' var should be empty"
  assert_equals "Unable to create temporary file" "$(< "$stderr_file")" "stderr should contain error message"
  assert_equals "1" "$ret_code" "should return 1"
}


test_tmpfile.new_returns_1_if_trap_fails() {
  local stdout_file
  local stderr_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file"

  fake_mktemp() {
    echo "test_file"
  }

  bg.trap.add() {
    return 1
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "${filename:-}" "'filename' var should be empty"
  assert_equals "Unable to set exit trap to delete file 'test_file'" "$(< "$stderr_file")" "stderr should contain error message"
  assert_equals "1" "$ret_code" "should return 1"
}
