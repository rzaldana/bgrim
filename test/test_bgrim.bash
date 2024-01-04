#!/usr/bin/env bash

################################################################################

setup_suite() {
  LIBRARY_NAME="bgrim.bash"

  # Get the absolute path of the library under test
  LIBRARY_PATH="$(cd ..>/dev/null && pwd)/$LIBRARY_NAME"

  # source library
  # shellcheck src=../bgrim.bash
  source "$LIBRARY_PATH"
}

test_is_empty_returns_0_if_given_no_args() {
  stdout_and_stderr="$(bg::is_empty 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when no arg is given"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_empty_returns_0_if_given_an_empty_string() {
  stdout_and_stderr="$(bg::is_empty "" 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when no arg is given"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_empty_returns_1_if_given_a_non_empty_string() {
  local test_var
  test_var="hello"
  stdout_and_stderr="$(bg::is_empty "$test_var" 2>&1)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when first arg is non-emtpy string"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_shell_bash_returns_0_if_running_in_bash() {
  local FAKE_BASH_VERSION="x.x.x"
  local _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
  stdout_and_stderr="$(bg::is_shell_bash 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when BASH_VERSION variable is set"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_shell_bash_returns_1_if_not_running_in_bash() {
  # shellcheck disable=SC2034
  local FAKE_BASH_VERSION=
  local _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
  stdout_and_stderr="$(bg::is_shell_bash 2>&1)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 0 when BASH_VERSION variable is unset"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_valid_var_name_returns_0_when_the_given_string_contains_only_alphanumeric_chars_and_underscore() {
  stdout_and_stderr="$(bg::is_valid_var_name "my_func" 2>&1)" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when given alphanumeric and underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_array_returns_0_if_there_is_an_array_with_the_given_name() {
  local -a my_test_array
  stdout_and_stderr="$(bg::is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when an array with that name exists"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_array_returns_1_if_there_is_no_set_variable_with_the_given_name() {
  stdout_and_stderr="$(bg::is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when no variable with the given name is set" 
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_array_returns_1_if_a_var_with_the_given_name_exists_but_is_not_an_array() {
  # shellcheck disable=SC2034
  local my_test_array="test_val"
  stdout_and_stderr="$(bg::is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when variable with given name is not an array" 
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_valid_var_name_returns_1_when_the_given_string_contains_non_alphanumeric_or_underscore_chars() {
  stdout_and_stderr="$(bg::is_valid_var_name "my.func" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when given non-alphanum or underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_in_array_returns_0_when_the_given_value_is_in_the_array_with_the_given_name() {
  local -a test_array=( "val1" "val2" "val3" ) 
  stdout_and_stderr="$(bg::in_array "val2" "test_array" 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when value is present in array with given name"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_in_array_returns_1_when_the_given_value_is_not_in_the_array_with_the_given_name() {
  local -a test_array=( "val1" "val2" "val3" ) 
  stdout_and_stderr="$(bg::in_array "val4" "test_array" 2>&1)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when value is not present in array with given name"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_in_array_returns_2_and_prints_error_message_when_an_array_with_the_given_name_doesnt_exist() {
  local stderr_file
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2317
  cleanup() {
    rm -f "$stderr_file"
  }
  trap cleanup EXIT
  stdout="$(bg::in_array "val4" "test_array" 2>"$stderr_file")"
  ret_code="$?"
  assert_equals "2" "$ret_code" "function call should return 2 when array with given name doesn't exist" 
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals "The array with name 'test_array' does not exist" "$(cat "$stderr_file")" "stderr should contain error message"
}

test_is_function_returns_0_when_given_the_name_of_a_function_in_the_env() {
  local stdout_and_stderr

  # shellcheck disable=SC2317
  test_fn() {
    echo "test" 
  }

  stdout_and_stderr="$(bg::is_function test_fn)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "is_function should return 0 when the given fn is defined"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_function_returns_0_when_the_given_name_does_not_refer_to_a_function() {
  local stdout_and_stderr
  local test_fn

  stdout_and_stderr="$(bg::is_function test_fn)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "is_function should return 1 when the given fn is not defined"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_clear_options_clears_all_options_in_the_environment() {
  # Set a few specific options
  set -o pipefail
  set -o vi
  shopt -s extglob

  local stderr_file
  local stdout_file
  stderr_file="$(mktemp)"
  stdout_file="$(mktemp)"

  # Cleanup stderr and stdout files on exit
  # shellcheck disable=SC2317
  cleanup() {
    rm -f "$stderr_file"
    rm -f "$stdout_file"
  }
  trap cleanup EXIT

  # Run function 
  bg::clear_options >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"

  # Stderr and stdout are empty
  assert_equals "" "$(cat "$stderr_file")" "stderr should be empty"
  assert_equals "" "$(cat "$stdout_file")" "stdout should be empty"

  # Return code is 0
  assert_equals "0" "$ret_code" "function code should return 0 if all options were unset"

  # All shell options are unset
  assert_equals "" "$-" '$- should expand to an empty string but it doesn'\''t'

  # All bash-specific options are unset
  assert_equals "" "$(shopt -s)" 'There should be no set bash-specific options'
}

