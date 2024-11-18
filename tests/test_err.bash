#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  __BG_TEST_MODE="true"
  tst.source_lib_from_root "err.bash"
  tst.source_lib_from_root "var.bash"
  __BG_ERR_FORMAT="%s\n"
}

test_err.print_prints_formatted_error_message_to_stderr_using_format_specified_in___BG_ERR_FORMAT() {
  tst.create_buffer_files
  set -euo pipefail
  __BG_ERR_FORMAT='error: %s\n'
  bg.err.print "my error message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "error: my error message" "$(< "$stderr_file")"
}

test_err.__BG_ERR_FORMAT_is_set_to_a_default_after_sourcing_library() {
  set -euo pipefail
  tst.create_buffer_files
  unset __BG_ERR_FORMAT  
  tst.source_lib_from_root "err.bash"
  bg.var.is_set "__BG_ERR_FORMAT"
  bg.err.print "my error message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "ERROR: my error message" "$(< "$stderr_file")"
}

test_err.print_prints_formatted_error_message_to_file_specified_in___BG_ERR_OUT() {
  tst.create_buffer_files
  __BG_ERR_OUT="$stdout_file"
  set -euo pipefail
  local stdout_and_stderr
  stdout_and_stderr="$(bg.err.print "my error message" 2>&1 )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
  assert_equals "my error message" "$(< "$stdout_file")"
}

test_err.__BG_ERR_OUT_is_set_to_a_default_after_sourcing_library() {
  set -euo pipefail
  unset __BG_ERR_OUT  
  tst.source_lib_from_root "err.bash"
  __BG_ERR_FORMAT="%s\n"
  bg.var.is_set "__BG_ERR_OUT"
  tst.create_buffer_files
  bg.err.print "my error message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "my error message" "$(< "$stderr_file")"  
}

test_err.print_returns_0_even_if_printf_errors_out() {
  tst.create_buffer_files
  set -euo pipefail
  #shellcheck disable=SC2317
  printf() {
    return 1 
  }
  bg.err.print "my error message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}

test_err.print_returns_0_even_if_no_message_is_provided() {
  tst.create_buffer_files
  set -euo pipefail
  #shellcheck disable=SC2317
  bg.err.print >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}





