#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  export __BG_TEST_MODE="true"
  tst.source_lib_from_root "env.bash"
  tst.source_lib_from_root "trap.bash"
  export __BG_ERR_FORMAT='%s\n'
}

test_env.clear_shell_opts_clears_all_shell_and_bash_specific_options_in_the_environment() {
  # Set a few specific options
  set -euo pipefail
  set -o vi
  shopt -s extglob

  tst.create_buffer_files

  # Run function 
  ret_code=0
  bg.env.clear_shell_opts >"$stdout_file" 2>"$stderr_file" || ret_code="$?"

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

test_env.clear_vars_with_prefix_unsets_all_vars_with_the_given_prefix() {
  set -euo pipefail
  tst.create_buffer_files

  # declare some variables
  PREFIX_MY_VAR="my value"
  export PREFIX_ENV_VAR="env value"
  local PREFIX_LOCAL_VAR="local value"
  bg.env.clear_vars_with_prefix "PREFIX_" 2>"$stderr_file" >"$stdout_file"
  exit_code="$?"

  local was_prefix_var_empty
  if declare -p 'prefix' &>/dev/null; then
    was_prefix_var_empty="false"
  else
    was_prefix_var_empty="true"
  fi

  assert_equals "true" "$was_prefix_var_empty" 
  assert_equals "0" "$exit_code"
  assert_equals "" "$(< "$stderr_file")"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "${PREFIX_MY_VAR:-}" "PREFIX_MY_VAR should be empty"
  assert_equals "" "${PREFIX_ENV_VAR:-}" "PREFIX_ENV_VAR should be empty"
  assert_equals "" "${PREFIX_LOCAL_VAR:-}" "PREFIX_LOCAL_VAR should be empty"
}

test_env.clear_vars_with_prefix_returns_error_if_prefix_is_not_a_valid_var_name() {
  set -euo pipefail
  tst.create_buffer_files

  # declare some variables
  PREFIX_MY_VAR='my value'
  export PREFIX_ENV_VAR="env value"
  local PREFIX_LOCAL_VAR="local value"
  bg.env.clear_vars_with_prefix '*' 2>"$stderr_file" >"$stdout_file" \
    || exit_code="$?"
  assert_equals "1" "$exit_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "'*' is not a valid variable prefix" "$(< "$stderr_file")"
  assert_equals "my value" "${PREFIX_MY_VAR:-}" "PREFIX_MY_VAR should be empty"
  assert_equals "env value" "${PREFIX_ENV_VAR:-}" "PREFIX_ENV_VAR should be empty"
  assert_equals "local value" "${PREFIX_LOCAL_VAR:-}" "PREFIX_LOCAL_VAR should be empty"

}

test_env.is_shell_opt_set_returns_0_if_the_given_option_is_set() {
  set -euo pipefail
  local test_opt="pipefail"
  local stdout_and_stderr
  set -o "$test_opt" 
  stdout_and_stderr="$( bg.env.is_shell_opt_set "$test_opt" )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_env.is_shell_opt_set_returns_1_if_the_given_option_is_not_set() {
  local test_opt="pipefail"
  local stdout_and_stderr
  set +o "$test_opt" 
  stdout_and_stderr="$( bg.env.is_shell_opt_set "$test_opt" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_env.is_shell_opt_set_returns_2_if_the_given_option_is_not_valid() {
  local test_opt="ipefail"
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file"
  stdout="$( bg.env.is_shell_opt_set "$test_opt" 2>"$stderr_file" )"
  ret_code="$?"
  assert_equals "2" "$ret_code"
  assert_equals "" "$stdout"
  assert_equals "'ipefail' is not a valid shell option" "$(< "$stderr_file")"
}

test_env.get_parent_routine_name_returns_name_of_parent_of_currently_executing_func_if_within_nested_func() {
  set -euo pipefail
  tst.create_buffer_files

  test_func1() {
    bg.env.get_parent_routine_name
  }

  test_func2() {
    test_func1 
  }


  test_func2 >"$stdout_file" 2>"$stderr_file" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "test_func2" "$(< "$stdout_file")" "stdout should contain 'test_func2'"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_env.get_parent_routine_name_returns_name_of_script_if_executing_at_top_level() {
  set -euo pipefail
  tst.create_buffer_files
  ./test_scripts/get_parent_routine1.bash >"$stdout_file" 2>"$stderr_file" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "get_parent_routine1.bash" "$(< "$stdout_file")" "stdout should contain 'get_parent_routine.bash'"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_get_parent_routine_name_returns_name_of_script_if_currently_executing_func_is_at_top_level() {
  set -euo pipefail
  tst.create_buffer_files
  ./test_scripts/get_parent_routine2.bash >"$stdout_file" 2>"$stderr_file" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "get_parent_routine2.bash" "$(< "$stdout_file")" "stdout should contain 'get_parent_routine.bash'"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_get_parent_script_name_returns_name_of_script_currently_executing_if_called_from_parent_script() {
  set -euo pipefail
  tst.create_buffer_files
  ./test_scripts/get_parent_script1.bash >"$stdout_file" 2>"$stderr_file" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "get_parent_script1.bash" "$(< "$stdout_file")" "stdout should contain 'get_parent_script1.bash'"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_get_parent_script_name_returns_name_of_script_currently_executing_if_called_from_sourced_lib() {
  set -euo pipefail
  tst.create_buffer_files
  ./test_scripts/get_parent_script2.bash >"$stdout_file" 2>"$stderr_file" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "get_parent_script2.bash" "$(< "$stdout_file")" "stdout should contain 'get_parent_script2.bash'"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}
