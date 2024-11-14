#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  __BG_TEST_MODE="true"
  tst.source_lib_from_root "in.bash"
  __BG_ERR_FORMAT='%s\n'
}



#test_is_shell_bash_returns_0_if_running_in_bash() {
#  local FAKE_BASH_VERSION="x.x.x"
#  local _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
#  stdout_and_stderr="$(core.is_shell_bash 2>&1)"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "function call should return 0 when BASH_VERSION variable is set"
#  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
#}

#test_is_shell_bash_returns_1_if_not_running_in_bash() {
  # shellcheck disable=SC2034
#  local FAKE_BASH_VERSION=
#  local _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
#  stdout_and_stderr="$(core.is_shell_bash 2>&1)"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "function call should return 0 when BASH_VERSION variable is unset"
#  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
#}

test_in.require_args_returns_2_if_required_args_array_is_not_set() {
  tst.create_buffer_files
  bg.in.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "'required_args' array not found" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_0_even_if_required_args_array_is_empty() {
  tst.create_buffer_files
  local -a required_args=()
  bg.in.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_in.require_args_returns_1_if_only_one_arg_is_required_and_none_are_provided() {
  tst.create_buffer_files
  local -a required_args=( "ARG" )
  bg.in.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "argument 1 (ARG) is required but was not provided" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_0_if_only_one_arg_is_required_and_its_provided() {
  set -euo pipefail
  tst.create_buffer_files
  local -a required_args=( "ARG" )
  bg.in.require_args "val1" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "" \
    "$(< "$stderr_file")" \
    "stderr should be emtpy"
  assert_equals "val1" "$ARG" "variable 'ARG' should contain value of argument"
}

test_in.require_args_returns_1_if_two_args_are_required_but_only_one_is_provided() {
  tst.create_buffer_files
  local -a required_args=( "ARG1" "ARG2" )
  bg.in.require_args "myvalue" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "argument 2 (ARG2) is required but was not provided" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_0_if_two_args_are_required_and_two_args_are_provided() {
  set -euo pipefail
  tst.create_buffer_files
  local -a required_args=( "ARG1" "ARG2" )
  bg.in.require_args "myvalue1" "myvalue2" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "" \
    "$(< "$stderr_file")" \
    "stderr should be empty"
  assert_equals "$ARG1" "myvalue1" "variable 'ARG1' should contain value of argument"
  assert_equals "$ARG2" "myvalue2" "variable 'ARG2' should contain value of argument"
}

test_in.require_args_returns_0_if_three_args_are_required_and_three_args_are_provided() {
  set -euo pipefail
  tst.create_buffer_files
  local -a required_args=( "ARG1" "ra:myarray" "ARG2" )
  local -a new_array=()
  bg.in.require_args "myvalue1" "new_array" "myvalue2" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "" \
    "$(< "$stderr_file")" \
    "stderr should be empty"
  assert_equals "$ARG1" "myvalue1" "variable 'ARG1' should contain value of argument"
  assert_equals "$ARG2" "myvalue2" "variable 'ARG2' should contain value of argument"
  assert_equals "$myarray" "new_array" "variable 'myarray' should contain value of argument"
}

test_in.require_args_returns_1_if_three_args_are_required_and_three_args_are_provided_but_arr_is_invalid() {
  set -uo pipefail
  tst.create_buffer_files
  local -a required_args=( "ARG1" "ra:myarray" "ARG2" )
  local -a new_array
  bg.in.require_args "myvalue1" "new_array" "myvalue2" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "array variable with name 'new_array' is not set" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_1_if_any_of_the_required_args_is_not_a_valid_variable_name() {
  tst.create_buffer_files
  local -a required_args=( "var()" "ARG2" )
  bg.in.require_args "myvalue1 myvalue2" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "'var()' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_1_if_readable_array_arg_is_required_but_a_regular_string_is_provided() {
  tst.create_buffer_files
  local -a required_args=( "ra:myarray" )
  bg.in.require_args "nonarray" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "array variable with name 'nonarray' does not exist" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_1_if_readable_array_arg_is_required_but_unset_array_variable_is_provided() {
  tst.create_buffer_files
  local -a an_array
  local -a required_args=( "ra:myarray" )
  bg.in.require_args "an_array" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "array variable with name 'an_array' is not set" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_0_if_readable_array_arg_is_required_and_set_array_variable_is_provided() {
  tst.create_buffer_files
  local -a another_array=()
  local -a required_args=( "ra:myarray")
  bg.in.require_args "another_array" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_in.require_args_returns_0_if_readable_array_arg_is_required_and_set_readonly_array_variable_is_provided() {
  tst.create_buffer_files
  local -ra another_array=()
  local -a required_args=( "ra:myarray")
  bg.in.require_args "another_array" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}


test_in.require_args_returns_1_if_readwrite_array_arg_is_required_but_a_regular_string_is_provided() {
  tst.create_buffer_files
  local -a required_args=( "rwa:myarray" )
  bg.in.require_args "nonarray" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "array variable with name 'nonarray' does not exist" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_1_if_readwrite_array_arg_is_required_but_unset_array_variable_is_provided() {
  tst.create_buffer_files
  local -a an_array
  local -a required_args=( "rwa:myarray" )
  bg.in.require_args "an_array" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "array variable with name 'an_array' is not set" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_1_if_readable_array_arg_is_required_and_set_read_only_array_variable_is_provided() {
  tst.create_buffer_files
  local -ra another_array=()
  local -a required_args=( "rwa:myarray")
  bg.in.require_args "another_array" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "array variable with name 'another_array' is read-only" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_0_if_readable_array_arg_is_required_and_set_writable_array_variable_is_provided() {
  tst.create_buffer_files
  local -a another_array=()
  local -a required_args=( "rwa:myarray")
  bg.in.require_args "another_array" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_in.require_args_returns_1_if_invalid_prefix_is_provided() { 
  tst.create_buffer_files
  local -a required_args=( "dwa:myarray")
  bg.in.require_args "another_array" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "Type prefix 'dwa' for variable 'myarray' is not valid. Valid prefixes are: 'ra' and 'rwa'" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_places_args_with_spaces_in_correct_variable() {
  set -o pipefail
  local var1
  local var2
  test_func(){
    local -a required_args=( "var1" "var2" )
    if ! bg.in.require_args "$@"; then
      return 2
    fi
  }
  tst.create_buffer_files
  test_func "a value" "second value" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "$var1" "a value"
  assert_equals "$var2" "second value"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}

