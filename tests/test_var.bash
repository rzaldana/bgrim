#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  export __BG_TEST_MODE="true"
  tst.source_lib_from_root "var.bash"
  export __BG_ERR_FORMAT='%s\n'
}

test_var.is_array_returns_2_if_no_argument_is_provided() {
  tst.create_buffer_files
  set -o pipefail
  bg.var.is_array >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "argument 1 (array_name) is required but was not provided" "$(< "$stderr_file")"
}

test_var.is_array_returns_0_if_there_is_an_array_variable_with_the_given_name_and_the_variable_is_set() {
  local -a my_test_array
  set -euo pipefail
  stdout_and_stderr="$(bg.var.is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when an array with that name exists"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_var.is_array_returns_1_if_there_is_no_set_variable_with_the_given_name() {
  stdout_and_stderr="$(bg.var.is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when no variable with the given name is set" 
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_var.is_array_returns_1_if_a_var_with_the_given_name_exists_but_is_not_an_array() {
  # shellcheck disable=SC2034
  local my_test_array="test_val"
  stdout_and_stderr="$(bg.var.is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when variable with given name is not an array" 
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_var.is_declared_returns_0_if_a_variable_is_declared() {
  #set -euo pipefail
  tst.create_buffer_files
  local myvar
  bg.var.is_declared 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_declared_returns_1_if_a_variable_is_undeclared_and_nounset_is_set() {
  tst.create_buffer_files
  set -u
  bg.var.is_declared 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_declared_returns_1_if_a_variable_is_undeclared() {
  tst.create_buffer_files
  unset myvar
  bg.var.is_declared 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_declared_returns_2_and_error_message_if_no_args_are_provided() {
  tst.create_buffer_files
  unset myvar
  bg.var.is_declared >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals 'argument 1 (var_name) is required but was not provided' "$(< "$stderr_file")" "stderr should contain error messsage"
}

test_var.is_set_returns_2_and_error_message_if_no_args_are_provided() {
  tst.create_buffer_files
  unset myvar
  bg.var.is_set >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals 'argument 1 (var_name) is required but was not provided' "$(< "$stderr_file")"
}

test_var.is_set_returns_1_if_a_variable_is_undeclared() {
  tst.create_buffer_files
  unset myvar
  bg.var.is_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_set_returns_0_if_a_variable_is_declared_and_set() {
  tst.create_buffer_files
  unset myvar
  local myvar=
  bg.var.is_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_set_returns_1_if_a_variable_is_declared_but_unset() {
  tst.create_buffer_files
  unset myvar
  local myvar
  bg.var.is_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_set_returns_0_if_an_integer_variable_is_declared_and_set() {
  tst.create_buffer_files
  unset myvar
  local -i myvar=0
  bg.var.is_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_set_returns_1_if_an_integer_variable_is_declared_but_unset() {
  tst.create_buffer_files
  unset myvar
  local -i myvar
  bg.var.is_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_readonly_returns_2_if_no_args_are_provided() {
  tst.create_buffer_files
  bg.var.is_readonly >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "argument 1 (var_name) is required but was not provided" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_readonly_returns_1_if_variable_is_unset() {
  tst.create_buffer_files
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_readonly_returns_1_if_variable_is_set_but_not_readonly() {
  tst.create_buffer_files
  declare myvar
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_readonly_returns_0_if_variable_is_readonly() {
  set -euo pipefail
  tst.create_buffer_files
  declare -r myvar
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_var.is_readonly_returns_0_if_variable_is_readonly_and_has_other_attributes() {
  set -euo pipefail
  tst.create_buffer_files
  declare -ra myvar
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}
