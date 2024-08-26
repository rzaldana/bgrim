#!/usr/bin/env bash


setup_suite() {
  LIBRARY_NAME="bgrim.bash"

  # Get the absolute path of the library under test
  LIBRARY_PATH="$(cd ../..>/dev/null && pwd)/$LIBRARY_NAME"

  # source library
  # shellcheck source=../bgrim.bash
  source "$LIBRARY_PATH" \
    || { echo "Unable to source library at $LIBRARY_PATH"; exit 1; }

  # set unofficial strict mode
  # (all functions should work in strict mode)
  #set -euo pipefail
}

rm_on_exit() {
  # Check that at least one arg was provided
  [[ "$#" -gt 0 ]] || { echo "rm_on_exit: No file names were provided" >&2; return 1; }

  # shellcheck disable=SC2317 
  cleanup_fn() {
    # Change permissions
    for file in "$@"; do
      chmod 0500 "$file"
    done

    # Remove file
    rm_output="$(rm -rf "$@" 2>&1)" \
      || { echo "Unable to remove temporary file. Output from 'rm':  $rm_output" >&2; return 1; }
  }

  # shellcheck disable=SC2064
  trap "cleanup_fn $*" EXIT
}

create_buffer_files() {
  stderr_file="$(mktemp)"  
  stdout_file="$(mktemp)"
  rm_on_exit "$stdout_file" "$stderr_file"
}


test_trap_can_set_two_traps() {
  ./test_scripts/trap.bash
}

test_tmpfile_creates_two_temporary_files() {
  ./test_scripts/tmpfile.bash
}

##########################################################################################
# Parse with one opt
##########################################################################################
parse_with_one_opt() {
  bg.cli.parse "$@" < <(
    bg.cli.init \
      | bg.cli.add_opt "f" "flag" "myflag" "help message"
  )
}

test_cli_parse_with_one_opt_and_no_args() {
  set -euo pipefail
  create_buffer_files
  parse_with_one_opt >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_fail "bg.is_var_set 'myflag'" "var 'myflag' should not be set"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_cli_parse_with_one_opt_and_one_short_arg() {
  set -euo pipefail
  create_buffer_files
  parse_with_one_opt -f >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert "bg.is_var_set 'myflag'" "var 'myflag' should be set"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}


test_cli_parse_with_one_opt_and_invalid_opt() {
  create_buffer_files
  parse_with_one_opt -g >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
  assert_fail "bg.is_var_set 'myflag'" "var 'myflag' should not be set"
}

test_cli_parse_with_one_opt_and_invalid_long_arg() {
  create_buffer_files
  parse_with_one_opt --invalid >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '--invalid' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
  assert_fail "bg.is_var_set 'myflag'" "var 'myflag' should not be set"
}


test_cli_parse_with_one_opt_and_valid_with_invalid_opt1() {
  create_buffer_files
  parse_with_one_opt -f -g >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli_parse_with_one_opt_and_valid_with_invalid_opt2() {
  create_buffer_files
  parse_with_one_opt -g -f >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}


test_cli_parse_with_one_opt_and_valid_with_invalid_opt3() {
  create_buffer_files
  parse_with_one_opt -g --flag >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli_parse_with_one_opt_and_valid_with_invalid_opt4() {
  create_buffer_files
  parse_with_one_opt --invalid -f >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '--invalid' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli_parse_with_one_opt_and_one_arg_with_opt() {
  set -euo pipefail
  create_buffer_files
  parse_with_one_opt -f 'myarg' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert "bg.is_var_set 'myflag'" "var 'myflag' should be set"
  assert_equals "" "$myflag" "'myflag' should contain an empty string"
}

test_cli_parse_with_one_opt_prints_help() {
  set -euo pipefail
  create_buffer_files
  parse_with_one_opt -h >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  local help_message
  IFS= read -d '' help_message <<EOF || true
parse_with_one_opt

Usage: parse_with_one_opt [options]

-f, --flag help message
EOF

  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "$( printf "%s" "${help_message}")" \
    "$(< "$stderr_file")" "stderr should contain help message"
  assert_fail "bg.is_var_set 'myflag'" "var 'myflag' should NOT be set"
  #assert_equals "" "$myflag" "'myflag' should contain an empty string"
}
