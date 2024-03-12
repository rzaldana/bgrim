#!/usr/bin/env bash

################################################################################
# description: |
#   creates a trap that will delete the given filenames when the 
#   current shell exits. This only works here because bash_unit runs each
#   unit test function in a separate subshell, so any execute trap declared 
#   within a test will execute when the subshell exits, i.e., when the test
#   is finished running. The command can only be used once for each test. 
#   Subsequent calls will overwrite previous traps.
# inputs:
#   stdin:
#   args:
# outputs:
#   stdout:
#   stderr:
#   return_code:
# Returns:
#   0: if the first argument is missing or an empty string 
#   1: otherwise
################################################################################
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
  set -euo pipefail
}

test_clear_shell_opts_clears_all_shell_and_bash_specific_options_in_the_environment() {
  # Set a few specific options
  set -o pipefail
  set -o vi
  shopt -s extglob

  local stderr_file
  local stdout_file
  stderr_file="$(mktemp)"
  stdout_file="$(mktemp)"

  # Cleanup stderr and stdout files on exit
  rm_on_exit "$stderr_file" "$stdout_file"

  # Run function 
  bg.clear_shell_opts >"$stdout_file" 2>"$stderr_file"
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

test_clear_traps_clears_all_traps_set_in_the_current_and_parent_environment() {
  stderr_file="$(mktemp)"
  func_stdout_file="$(mktemp)"
  total_stdout_file="$(mktemp)"
  ret_code_file="$(mktemp)"

  # Cleanup stderr and stdout files on exit
  rm_on_exit "$stderr_file" "$func_stdout_file" "$ret_code_file" "$total_stdout_file"

  # set -o functrace so return traps are inherited by subshell
  set -o functrace

  # set -o errtrace so ERR traps are inherited by subshell
  set -o errtrace

  trap 'true' RETURN
  trap 'true' ERR
  
  # Run function in subshell
  (
    # Define traps
    trap 'true' EXIT >/dev/null 2>&1
    trap 'true' SIGINT >/dev/null 2>&1

    bg.clear_traps >"$func_stdout_file"
    echo "$?" > "$ret_code_file"

    # After clearing
    trap >/dev/null
  ) >"$total_stdout_file"

  assert_matches "trap -- 'true' RETURN" "$(trap)"
  assert_matches "trap -- 'true' ERR" "$(trap)"
  assert_matches "trap -- '.+' EXIT" "$(trap)"
  
  # Return code is 0
  assert_equals "0" "$(< "$ret_code_file")" "return code should be 0"
  
  # stderr is empty
  assert_equals "" "$(> "$ret_code_file")" "stderr should be empty"
 
  # total stdout is empty 
  assert_equals "" "$(< "$total_stdout_file")" "stdout from test run does not match expected value"

  # func stdout is empty
  assert_equals "" "$( < "$func_stdout_file")" "stdout from function is not empty"
  
}

test_clear_vars_with_prefix_unsets_all_vars_with_the_given_prefix() {
  stderr_file="$(mktemp)"
  stdout_file="$(mktemp)"
  rm_on_exit "$stderr_file" "$stdout_file"

  # declare some variables
  PREFIX_MY_VAR="my value"
  export PREFIX_ENV_VAR="env value"
  local PREFIX_LOCAL_VAR="local value"
  bg.clear_vars_with_prefix "PREFIX_" 2>"$stderr_file" >"$stdout_file"
  exit_code="$?"

  assert_equals "0" "$exit_code"
  assert_equals "" "$(< "$stderr_file")"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "${PREFIX_MY_VAR:-}" "PREFIX_MY_VAR should be empty"
  assert_equals "" "${PREFIX_ENV_VAR:-}" "PREFIX_ENV_VAR should be empty"
  assert_equals "" "${PREFIX_LOCAL_VAR:-}" "PREFIX_LOCAL_VAR should be empty"
}

test_clear_vars_with_prefix_returns_error_if_first_param_is_empty() {
  stderr_file="$(mktemp)"
  stdout_file="$(mktemp)"
  rm_on_exit "$stderr_file" "$stdout_file"

  # declare some variables
  PREFIX_MY_VAR="my value"
  export PREFIX_ENV_VAR="env value"
  local PREFIX_LOCAL_VAR="local value"
  bg.clear_vars_with_prefix 2>"$stderr_file" >"$stdout_file"
  exit_code="$?"

  assert_equals "1" "$exit_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "ERROR: arg1 (prefix) is empty but is required" "$(< "$stderr_file")"
  assert_equals "my value" "${PREFIX_MY_VAR:-}" "PREFIX_MY_VAR should be empty"
  assert_equals "env value" "${PREFIX_ENV_VAR:-}" "PREFIX_ENV_VAR should be empty"
  assert_equals "local value" "${PREFIX_LOCAL_VAR:-}" "PREFIX_LOCAL_VAR should be empty"

}

test_clear_vars_with_prefix_returns_error_if_prefix_is_not_a_valid_var_name() {
  stderr_file="$(mktemp)"
  stdout_file="$(mktemp)"
  rm_on_exit "$stderr_file" "$stdout_file"

  # declare some variables
  PREFIX_MY_VAR='my value'
  export PREFIX_ENV_VAR="env value"
  local PREFIX_LOCAL_VAR="local value"
  bg.clear_vars_with_prefix '*' 2>"$stderr_file" >"$stdout_file" \
    || exit_code="$?"
  assert_equals "1" "$exit_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "ERROR: '*' is not a valid variable prefix" "$(< "$stderr_file")"
  assert_equals "my value" "${PREFIX_MY_VAR:-}" "PREFIX_MY_VAR should be empty"
  assert_equals "env value" "${PREFIX_ENV_VAR:-}" "PREFIX_ENV_VAR should be empty"
  assert_equals "local value" "${PREFIX_LOCAL_VAR:-}" "PREFIX_LOCAL_VAR should be empty"

}

test_is_empty_returns_0_if_given_no_args() {
  stdout_and_stderr="$(bg.is_empty 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when no arg is given"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}
test_is_empty_returns_0_if_given_an_empty_string() {
  stdout_and_stderr="$(bg.is_empty "" 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when no arg is given"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_empty_returns_1_if_given_a_non_empty_string() {
  local test_var
  test_var="hello"
  stdout_and_stderr="$(bg.is_empty "$test_var" 2>&1)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when first arg is non-emtpy string"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

#test_is_shell_bash_returns_0_if_running_in_bash() {
#  local FAKE_BASH_VERSION="x.x.x"
#  local _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
#  stdout_and_stderr="$(bg.is_shell_bash 2>&1)"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "function call should return 0 when BASH_VERSION variable is set"
#  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
#}

#test_is_shell_bash_returns_1_if_not_running_in_bash() {
  # shellcheck disable=SC2034
#  local FAKE_BASH_VERSION=
#  local _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
#  stdout_and_stderr="$(bg.is_shell_bash 2>&1)"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "function call should return 0 when BASH_VERSION variable is unset"
#  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
#}

test_is_valid_var_name_returns_0_when_the_given_string_contains_only_alphanumeric_chars_and_underscore() {
  stdout_and_stderr="$(bg.is_valid_var_name "my_func" 2>&1)" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when given alphanumeric and underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_valid_var_name_returns_1_when_the_given_string_contains_non_alphanumeric_or_underscore_chars() {
  stdout_and_stderr="$(bg.is_valid_var_name "my.func" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when given non-alphanum or underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_valid_var_name_returns_1_when_the_given_string_starts_with_a_number() {
  stdout_and_stderr="$(bg.is_valid_var_name "1my_func" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when given non-alphanum or underscore chars"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_array_returns_0_if_there_is_an_array_with_the_given_name() {
  local -a my_test_array
  stdout_and_stderr="$(bg.is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when an array with that name exists"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_array_returns_1_if_there_is_no_set_variable_with_the_given_name() {
  stdout_and_stderr="$(bg.is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when no variable with the given name is set" 
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_array_returns_1_if_a_var_with_the_given_name_exists_but_is_not_an_array() {
  # shellcheck disable=SC2034
  local my_test_array="test_val"
  stdout_and_stderr="$(bg.is_array "my_test_array" 2>&1)" 
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when variable with given name is not an array" 
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}


test_in_array_returns_0_when_the_given_value_is_in_the_array_with_the_given_name() {
  local -a test_array=( "val1" "val2" "val3" ) 
  stdout_and_stderr="$(bg.in_array "val2" "test_array" 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when value is present in array with given name"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_in_array_returns_1_when_the_given_value_is_not_in_the_array_with_the_given_name() {
  local -a test_array=( "val1" "val2" "val3" ) 
  stdout_and_stderr="$(bg.in_array "val4" "test_array" 2>&1)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when value is not present in array with given name"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_in_array_returns_2_and_prints_error_message_when_an_array_with_the_given_name_doesnt_exist() {
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"
  stdout="$(bg.in_array "val4" "test_array" 2>"$stderr_file")"
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

  stdout_and_stderr="$(bg.is_function test_fn)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "is_function should return 0 when the given fn is defined"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_function_returns_1_when_the_given_name_does_not_refer_to_a_function() {
  local stdout_and_stderr
  local test_fn

  stdout_and_stderr="$(bg.is_function test_fn)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "is_function should return 1 when the given fn is not defined"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_is_valid_command_returns_0_if_its_first_arg_is_a_function() {
  local stdout_and_stderr
  test_fn() {
    # shellcheck disable=SC2317
    return 0
  }
  stdout_and_stderr="$(bg.is_valid_command test_fn arg1)"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}


test_is_valid_command_returns_0_if_its_first_arg_is_a_shell_builtin() {
  local stdout_and_stderr
  stdout_and_stderr="$(bg.is_valid_command set arg1)"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_is_valid_command_returns_0_if_its_first_arg_is_an_executable_in_the_path() {
  local stdout_and_stderr
  stdout_and_stderr="$(bg.is_valid_command ls arg1)"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_is_valid_command_returns_1_if_its_first_arg_is_a_keyword() {
  local stdout_and_stderr
  stdout_and_stderr="$(bg.is_valid_command "{" "ls;" "}")"
  ret_code="$?"
  assert_equals "" "$stdout_and_stderr"
  assert_equals "1" "$ret_code"
}

test_map_runs_given_command_for_each_line_in_stdin() {
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  test_fn() {
    local test_var
    read -r test_var
    echo "test_fn: $test_var"
  }

  stdout="$( {
                echo "line1" 
                echo "line2"
                echo "line3"
              } |  bg.map test_fn 2>"$stderr_file")"
  ret_code="$?"
  assert_equals \
    "0" \
    "$ret_code" \
    "bg.map should return 0 when the function executes successfully for every line"
  assert_equals \
    'test_fn: line1
test_fn: line2
test_fn: line3' \
    "$stdout" \
    "stdout did not return the correct output" 
  assert_equals "" "$(<"$stderr_file")" "stderr should be empty"
}

test_map_runs_given_command_with_arguments_for_each_line_in_stdin() {
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  test_fn() {
    local test_var
    local first_arg="${1:-}"
    read -r test_var
    echo "test_fn: stdin: $test_var, arg1: $first_arg"
  }

  stdout="$( {
                echo "line1" 
                echo "line2"
                echo "line3"
              } |  bg.map test_fn hello 2>"$stderr_file")"
  ret_code="$?"
  assert_equals \
    "0" \
    "$ret_code" \
    "bg.map should return 0 when the function executes successfully for every line"
  assert_equals \
    'test_fn: stdin: line1, arg1: hello
test_fn: stdin: line2, arg1: hello
test_fn: stdin: line3, arg1: hello' \
    "$stdout" \
    "stdout did not return the correct output" 
  assert_equals "" "$(<"$stderr_file")" "stderr should be empty"
}

test_map_returns_1_when_first_arg_is_empty() {
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  test_fn() {
    local test_var
    read -r test_var
    echo "test_fn: $test_var"
  }

  stdout="$( {
                echo "line1" 
                echo "line2"
                echo "line3"
              } | bg.map 2>"$stderr_file")"
  ret_code="$?"
  assert_equals \
    "1" \
    "$ret_code" \
    "bg.map should return 1 when no args are provided"
  assert_equals \
    "" \
    "$stdout" \
    "stdout did not return the correct output" 
  assert_equals \
    "bg.map: no args were provided" \
    "$(<"$stderr_file")" \
    "stderr match expected error message"
}

test_map_returns_1_when_when_the_first_arg_does_not_refer_to_a_valid_command() {
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  stdout="$( {
                echo "line1" 
                echo "line2"
                echo "line3"
              } | bg.map "{ ls; }" 2>"$stderr_file")"
  ret_code="$?"
  assert_equals \
    "1" \
    "$ret_code" \
    "bg.map should return 1 when the passed in name is not a fn"
  assert_equals \
    "" \
    "$stdout" \
    "stdout did not return the correct output" 
  assert_equals \
    "bg.map: '{ ls; }' is not a valid function, shell built-in, or executable in the PATH" \
    "$(<"$stderr_file")" \
    "stderr match expected error message"
}

test_map_returns_1_when_when_a_command_execution_with_no_args_fails() {
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  execution=0

  # shellcheck disable=SC2317
  test_fn() {
    local test_var
    read -r test_var
    echo "test_fn: $test_var"
    if (( execution++ > 0)); then
      return 33
    fi
  }

  stdout="$( {
                echo "line1" 
                echo "line2"
                echo "line3"
              } | bg.map test_fn 2>"$stderr_file")"
  ret_code="$?"
  assert_equals \
    "1" \
    "$ret_code" \
    "bg.map should return 1 when a function execution fails"
  assert_equals \
    "test_fn: line1
test_fn: line2" \
    "$stdout" \
    "stdout did not return the correct output" 
  assert_equals \
    "bg.map: execution of command 'test_fn' failed with status code '33' for input 'line2'" \
    "$(<"$stderr_file")" \
    "stderr match expected error message"
}


test_map_returns_1_when_when_a_command_execution_with_args_fails() {
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  execution=0

  # shellcheck disable=SC2317
  test_fn() {
    local test_var
    read -r test_var
    echo "test_fn: $test_var"
    if (( execution++ > 0)); then
      return 33
    fi
  }
  
  stdout="$( {
                echo "line1" 
                echo "line2"
                echo "line3"
              } | bg.map test_fn arg1 "arg2 hello" 2>"$stderr_file")"
  ret_code="$?"
  assert_equals \
    "1" \
    "$ret_code" \
    "bg.map should return 1 when a function execution fails"
  assert_equals \
    "test_fn: line1
test_fn: line2" \
    "$stdout" \
    "stdout did not return the correct output" 
  assert_equals \
    "bg.map: execution of command 'test_fn' with args 'arg1' 'arg2 hello' failed with status code '33' for input 'line2'" \
    "$(<"$stderr_file")" \
    "stderr match expected error message"
}


test_filter_fails_when_no_args_are_provided() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"
  stdout="$( bg.filter 2>"$stderr_file" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout"
  assert_equals \
    "bg.filter: no args were provided" \
    "$(< "$stderr_file")"
}

test_filter_fails_when_its_first_arg_is_not_a_valid_command() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"
  stdout="$( bg.filter non_valid_command 2>"$stderr_file" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout"
  assert_equals \
    "bg.filter: 'non_valid_command' is not a valid function, shell built-in, or executable in the PATH" \
    "$(< "$stderr_file")"
}

test_filter_filters_out_lines_for_which_command_returns_0() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"
  # shellcheck disable=SC2317
  test_fn() {
    read -r line
    [[ "$line" == "skip" ]] && return 1 
    return 0
  }

  generate_output() {
    echo "print"
    echo "skip"
    echo "hello"
    echo "skip"
    echo "skip"
    echo "yes"
    echo "go" 
  }

  local ret_code
  stdout="$( generate_output | bg.filter test_fn 2>"$stderr_file" )"
  ret_code="$?"
  want_stdout="$(printf '%s\n%s\n%s\n%s\n' 'print' 'hello' 'yes' 'go')"
  #assert_equals "0" "$ret_code"
  assert_equals "$want_stdout" "$stdout"
  assert_equals "" "$(< "$stderr_file")"
}



#test_is_valid_long_option_returns_0_if_given_alphanumeric_string() {
#  local test_string="longOpt"
#  local stdout_and_stderr
#  stdout_and_stderr="$( bg.is_valid_long_option "$test_string" )"
#  ret_code="$?"
#  assert_equals "0" "$ret_code"
#  assert_equals "" "$stdout_and_stderr"
#}

test_is_valid_shell_opt_returns_0_if_given_a_valid_shell_option() {
  local test_opt="pipefail"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.is_valid_shell_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}


test_is_valid_shell_opt_returns_1_if_given_an_invalid_shell_option() {
  local test_opt="pipefai"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.is_valid_shell_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_is_valid_bash_opt_returns_0_if_given_a_valid_bash_option() {
  local test_opt="cdspell"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.is_valid_bash_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_is_valid_bash_opt_returns_1_if_given_an_invalid_bash_option() {
  local test_opt="dspell"
  local stdout_and_stderr
  stdout_and_stderr="$( bg.is_valid_bash_opt "$test_opt" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_is_shell_opt_set_returns_0_if_the_given_option_is_set() {
  local test_opt="pipefail"
  local stdout_and_stderr
  set -o "$test_opt" 
  stdout_and_stderr="$( bg.is_shell_opt_set "$test_opt" )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_is_shell_opt_set_returns_1_if_the_given_option_is_not_set() {
  local test_opt="pipefail"
  local stdout_and_stderr
  set +o "$test_opt" 
  stdout_and_stderr="$( bg.is_shell_opt_set "$test_opt" )"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
}

test_is_shell_opt_set_returns_2_if_the_given_option_is_not_valid() {
  local test_opt="ipefail"
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"
  stdout="$( bg.is_shell_opt_set "$test_opt" 2>"$stderr_file" )"
  ret_code="$?"
  assert_equals "2" "$ret_code"
  assert_equals "" "$stdout"
  assert_equals "'ipefail' is not a valid shell option" "$(< "$stderr_file")"
}


test_get_trap_command_returns_nothing_if_given_a_signal_that_does_not_have_a_trap() {
  local stdout_and_stderr
  stdout_and_stderr="$( 
  # Clear SIGINT trap
  trap - SIGINT 

  # Call function
  bg.get_trap_command 'SIGINT' 2>&1 
  )"

  ret_code="$?"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0 when trap is not set"
}

test_get_trap_command_returns_nothing_if_given_a_signal_with_an_ignore_trap() {
  local stdout_and_stderr
  stdout_and_stderr="$( 
  # Clear SIGINT trap
  trap '' SIGINT 

  # Call function
  bg.get_trap_command 'SIGINT' 2>&1 
  )"

  ret_code="$?"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0 when trap is not set"
}

test_get_trap_command_returns_trap_command_if_given_a_signal_that_has_a_trap() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"
  # Set SIGINT trap
  trap "$(cat <<HERE
echo hello
echo bye
HERE
)" SIGINT 

  stdout="$( 
    # Call function
    bg.get_trap_command 'SIGINT' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals $'echo hello\necho bye' "$stdout" "stdout should return trap command"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0 when trap is not set"
}

test_get_trap_command_returns_1_and_error_code_if_there_is_an_error_while_retrieving_the_trap() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  fake_trap() {
    echo "An Error occurred!" >&2
    return 1
  }

  fake trap fake_trap

  stdout="$( 
    # Call function
    bg.get_trap_command 'MYSIG' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals 'Error retrieving trap for signal '\''MYSIG'\''. Error message: '\''An Error occurred!'\''' "$(< "$stderr_file")" "stderr should contain an error message"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}

test_get_trap_command_returns_1_and_error_code_if_no_args_are_provided() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  stdout="$( 
    # Call function
    bg.get_trap_command 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals 'arg1 (signal_spec) not provided but required' "$(< "$stderr_file")" "stderr should contain an error message"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}

test_trap_returns_1_and_error_code_if_no_args_are_provided() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  stdout="$( 
    # Call function
    bg.trap 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals 'arg1 (trap_command) not provided but required' "$(< "$stderr_file")" "stderr should contain an error message"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}


test_trap_returns_1_and_error_code_if_only_one_arg_is_provided() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  stdout="$( 
    # Call function
    bg.trap 'command' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals 'arg2 (signal_spec) not provided but required' "$(< "$stderr_file")" "stderr should contain an error message"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}

test_trap_sets_a_trap_if_the_signal_spec_is_ignored() {
  local stdout_file
  local stderr_file
  local traps_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  traps_file="$(mktemp)"
  rm_on_exit "$stderr_file" "$stdout_file" "$traps_file"

  # Ignore trap
  trap '' SIGINT
 
  # Use function to set trap 
  bg.trap "echo hello" SIGINT 1>"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  
  # Get list of traps for SIGINT
  trap -p SIGINT >"$traps_file"

  assert_equals "0" "$ret_code" "return code should be 0 if the trap was added"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "trap -- 'echo hello' SIGINT" "$(< "$traps_file")" "SIGINT trap should contain 'echo hello'"
}


test_trap_sets_a_trap_if_the_signal_spec_doesnt_have_a_trap() {
  local stdout_file
  local stderr_file
  local traps_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  traps_file="$(mktemp)"
  rm_on_exit "$stderr_file" "$stdout_file" "$traps_file"

  # Clear trap
  trap '-' SIGINT
 
  # Use function to set trap 
  bg.trap "echo hello" SIGINT 1>"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  
  # Get list of traps for SIGINT
  trap -p SIGINT >"$traps_file"

  assert_equals "0" "$ret_code" "return code should be 0 if the trap was added"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "trap -- 'echo hello' SIGINT" "$(< "$traps_file")" "SIGINT trap should contain 'echo hello'"
}

test_trap_adds_a_command_to_the_trap_for_an_existing_signal_if_the_signal_already_has_a_trap() {
  local stdout_file
  local stderr_file
  local traps_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  traps_file="$(mktemp)"
  rm_on_exit "$stderr_file" "$stdout_file" "$traps_file"

  # Clear trap
  trap - SIGINT

  # Set initial trap
  trap "echo hello" SIGINT
 
  # Use function to set second trap 
  bg.trap "echo goodbye" SIGINT 1>"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  
  # Get list of traps for SIGINT
  traps="$(trap -p SIGINT)"

  assert_equals "0" "$ret_code" "return code should be 0 if the trap was added"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals 'trap -- '\'$'echo hello\necho goodbye'\'' SIGINT' "$traps" "SIGINT trap should contain both commands"
}

test_trap_returns_1_and_error_code_if_there_is_an_error_while_retrieving_the_existing_trap() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  fake_get_trap_command() {
    echo "An Error occurred!" >&2
    return 1
  }

  fake bg.get_trap_command fake_get_trap_command

  stdout="$( 
    # Call function
    bg.trap 'command' 'MYSIG' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals "Error retrieving existing trap for signal 'MYSIG'" "$(< "$stderr_file")" "stderr should contain an error message"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}


test_trap_returns_1_and_error_message_if_there_is_an_error_while_setting_the_new_trap() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  fake_trap() {
    [[ "${FAKE_PARAMS[0]:-}" != "-p" ]]  \
      && { echo "An Error occurred!" >&2; return 1; }
    echo 'fake_trap_command'
  }

  fake trap fake_trap 

  stdout="$( 
    # Call function
    bg.trap 'command' 'SIGINT' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals "Error setting new trap for signal 'SIGINT'" "$(< "$stderr_file")"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}

test_tmpfile_returns_1_when_no_args_provided() {
  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  bg.tmpfile >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "return code should be 1 when no args are provided"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: arg1 (filename_var) not provided but required" "$(< "$stderr_file")"
}


test_tmpfile_fails_when_filename_var_is_not_a_valid_var_name() {
  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  bg.tmpfile '$myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "return code should be 1 filename_var is not a valid var name"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '\$myvar' is not a valid variable name" "$(< "$stderr_file")"
}


test_tmpfile_invokes_mktemp_and_trap_function() {
  local stdout_file
  local stderr_file
  local tmpfile_name_file
  local trap_output_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  trap_output_file="$(mktemp)"
  tmpfile_name_file="$(mktemp)"
  rm_on_exit "$stdout_file" "$stderr_file" "$tmpfile_name_file" "$trap_output_file"

  fake_mktemp() {
    echo "test_file" >"$tmpfile_name_file"
    cat "$tmpfile_name_file"
  }

  bg.trap() {
    echo "1:$1" >"$trap_output_file"
    echo "2:$2" >>"$trap_output_file"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals \
    "$(printf "%s\n%s" "1:rm -f '$(< "$tmpfile_name_file")'" "2:EXIT")" \
    "$(< "$trap_output_file")"
  assert_equals "$(< "$tmpfile_name_file")" "$filename" "'filename' var should contain name of temp file"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0"
}


test_tmpfile_stores_tmpfilen_name_in_var_even_when_var_is_not_defined_beforehand() {
  local stdout_file
  local stderr_file
  local tmpfile_name_file
  local trap_output_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  trap_output_file="$(mktemp)"
  tmpfile_name_file="$(mktemp)"
  rm_on_exit "$stdout_file" "$stderr_file" "$tmpfile_name_file" "$trap_output_file"

  fake_mktemp() {
    echo "test_file" >"$tmpfile_name_file"
    cat "$tmpfile_name_file"
  }

  bg.trap() {
    echo "1:$1" >"$trap_output_file"
    echo "2:$2" >>"$trap_output_file"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile 'myfilename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals \
    "$(printf "%s\n%s" "1:rm -f '$(< "$tmpfile_name_file")'" "2:EXIT")" \
    "$(< "$trap_output_file")"
  assert_equals "$(< "$tmpfile_name_file")" "$myfilename" "'myfilename' var should contain name of temp file"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0"
}


test_tmpfile_returns_1_if_mktemp_fails() {
  local stdout_file
  local stderr_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  rm_on_exit "$stdout_file" "$stderr_file"

  fake_mktemp() {
    echo "ERROR!" >&2
    return 1
  }

  bg.trap() {
    echo "1:${1:-}"
    echo "2:${2:-}"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "${filename:-}" "'filename' var should be empty"
  assert_equals "$(printf "%s\n%s" "ERROR!" "ERROR: Unable to create temporary file")" "$(< "$stderr_file")" "stderr should contain error message"
  assert_equals "1" "$ret_code" "should return 1"
}


test_tmpfile_returns_1_if_trap_fails() {
  local stdout_file
  local stderr_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  rm_on_exit "$stdout_file" "$stderr_file"

  fake_mktemp() {
    echo "test_file"
  }

  bg.trap() {
    echo "ERROR!" >&2
    return 1
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "${filename:-}" "'filename' var should be empty"
  assert_equals "$(printf "%s\n%s" "ERROR!" "ERROR: Unable to set exit trap to delete file 'test_file'")" "$(< "$stderr_file")" "stderr should contain error message"
  assert_equals "1" "$ret_code" "should return 1"
}
