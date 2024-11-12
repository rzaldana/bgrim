#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "str.bash"
  __BG_ERR_FORMAT="%s\n"
}

test_str.is_valid_var_name_returns_0_when_the_given_string_contains_only_alphanumeric_chars_and_underscore() {
  set -euo pipefail
  ret_code=0
  stdout_and_stderr="$(bg.str.is_valid_var_name "my_func" 2>&1)"  || ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when given alphanumeric and underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_str.is_valid_var_name_returns_0_when_the_given_string_contains_a_single_letter() {
  set -euo pipefail
  ret_code=0
  stdout_and_stderr="$(bg.str.is_valid_var_name "a" 2>&1)"  || ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when given a single letter"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_str.is_valid_var_name_returns_1_when_the_given_string_contains_non_alphanumeric_or_underscore_chars() {
  set -euo pipefail
  ret_code=0
  stdout_and_stderr="$(bg.str.is_valid_var_name "my.func" 2>&1)" || ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when given non-alphanum or underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_str.is_valid_var_name_returns_1_when_the_given_string_starts_with_a_number() {
  set -euo pipefail
  ret_code=0
  stdout_and_stderr="$(bg.str.is_valid_var_name "1my_func" 2>&1)" || ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when given non-alphanum or underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_str.is_valid_var_name_returns_2_when_given_no_args() {
  set -euo pipefail
  ret_code=0
  tst.create_buffer_files
  bg.str.is_valid_var_name >"$stdout_file" 2>"$stderr_file" || ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout shouldb be empty"
  assert_equals \
    "argument 1 (var_name) is required but was not provided" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_str.is_valid_command_returns_0_if_its_first_arg_is_a_function() {
  set -euo pipefail
  local stdout_and_stderr
  test_fn() {
    # shellcheck disable=SC2317
    return 0
  }
  stdout_and_stderr="$(bg.str.is_valid_command test_fn arg1)"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}


test_str.is_valid_command_returns_0_if_its_first_arg_is_a_shell_builtin() {
  set -euo pipefail
  local stdout_and_stderr
  stdout_and_stderr="$(bg.str.is_valid_command set arg1)"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_str.is_valid_command_returns_0_if_its_first_arg_is_an_executable_in_the_path() {
  set -euo pipefail
  local stdout_and_stderr
  stdout_and_stderr="$(bg.str.is_valid_command ls arg1)"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_str.is_valid_command_returns_1_if_its_first_arg_is_a_keyword() {
  local stdout_and_stderr
  stdout_and_stderr="$(bg.str.is_valid_command "{" "ls;" "}")"
  ret_code="$?"
  assert_equals "" "$stdout_and_stderr"
  assert_equals "1" "$ret_code"
}

test_str.is_valid_shell_opt_returns_0_if_given_a_valid_shell_option() {
  set -euo pipefail
  local test_opt="pipefail"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.str.is_valid_shell_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}


test_str.is_valid_shell_opt_returns_1_if_given_an_invalid_shell_option() {
  local test_opt="pipefai"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.str.is_valid_shell_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_str.is_valid_bash_opt_returns_0_if_given_a_valid_bash_option() {
  set -euo pipefail
  local test_opt="cdspell"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.str.is_valid_bash_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_str.is_valid_bash_opt_returns_1_if_given_an_invalid_bash_option() {
  local test_opt="dspell"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.str.is_valid_bash_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_str.escape_single_quotes_returns_unchanged_string_if_it_has_no_single_quotes() {
  tst.create_buffer_files
  set -euo pipefail
  bg.str.escape_single_quotes "mystring" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "mystring" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}

test_str.escape_single_quotes_returns_string_with_escaped_single_quotes() {
  tst.create_buffer_files
  set -euo pipefail
  bg.str.escape_single_quotes "mys'tr'ing" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "mys'\''tr'\''ing" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}
