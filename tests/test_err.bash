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

test_err.get_stackframe:returns_same_information_as_caller_builtin_in_output_arr(){
  tst.create_buffer_files
  set -euo pipefail
  local -a stackframe=()
  __bg.err.get_stackframe "0" "stackframe" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
  rm "$stdout_file" "$stderr_file" 
  touch "$stdout_file" "$stderr_file"
  caller 0 >"$stdout_file"
  assert_equals "$(< "$stdout_file")" "${stackframe[0]} ${stackframe[1]} ${stackframe[2]}"
}

test_err.get_stackframe:returns_same_information_as_caller_builtin_in_output_arr_when_requesting_non_zero_frame(){
  tst.create_buffer_files
  set -euo pipefail
  local -a stackframe=()
  __bg.err.get_stackframe "1" "stackframe" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
  rm "$stdout_file" "$stderr_file" 
  touch "$stdout_file" "$stderr_file"
  caller 1 >"$stdout_file"
  assert_equals "$(< "$stdout_file")" "${stackframe[0]} ${stackframe[1]} ${stackframe[2]}"
}

test_err.get_stackframe:returns_same_information_as_caller_builtin_when_called_in_function_from_sourced_file(){
  tst.create_buffer_files
  set -euo pipefail
  . ./test_scripts/test_err.get_stackframe1.bash
  myfunc >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "$(< "$stdout_file" )" "$(< "$stderr_file")"
}

test_err.get_stackframe:returns_same_information_as_caller_builtin_when_called_in_function_from_sourced_file_in_nested_function(){
  tst.create_buffer_files
  set -euo pipefail
  . ./test_scripts/test_err.get_stackframe2.bash
  myfunc >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "$(< "$stdout_file" )" "$(< "$stderr_file")"
}

test_err.get_stackframe:returns_fails_when_caller_fails(){
  tst.create_buffer_files
  set -euo pipefail
  local caller_i=0
  while caller "$caller_i" >/dev/null 2>&1; do
    (( ++caller_i ))
  done

  local stackframe=()
  local get_stackframe_i=0
  while __bg.err.get_stackframe "$get_stackframe_i" 'stackframe' 2>"$stderr_file"; do
    (( ++get_stackframe_i ))
  done

  assert_equals "$caller_i" "$get_stackframe_i"
  assert_equals \
    "requested frame '${get_stackframe_i}' but there are only frames 0-$((get_stackframe_i-1)) in the call stack" \
    "$(< "$stderr_file" )"
}
