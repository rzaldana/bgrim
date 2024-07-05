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

create_buffer_files() {
  stderr_file="$(mktemp)"  
  stdout_file="$(mktemp)"
  rm_on_exit "$stdout_file" "$stderr_file"
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

test_is_valid_var_name_returns_2_when_given_no_args() {
  create_buffer_files
  bg.is_valid_var_name >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout shouldb be empty"
  assert_equals \
    "ERROR: bg.is_valid_var_name: argument 1 (var_name) is required but was not provided" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_clear_shell_opts_clears_all_shell_and_bash_specific_options_in_the_environment() {
  # Set a few specific options
  set -o pipefail
  set -o vi
  shopt -s extglob

  create_buffer_files

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
  create_buffer_files

  # declare some variables
  PREFIX_MY_VAR="my value"
  export PREFIX_ENV_VAR="env value"
  local PREFIX_LOCAL_VAR="local value"
  bg.clear_vars_with_prefix "PREFIX_" 2>"$stderr_file" >"$stdout_file"
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

test_clear_vars_with_prefix_returns_error_if_prefix_is_not_a_valid_var_name() {
  create_buffer_files

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

test_is_valid_long_opt_returns_1_if_string_does_not_start_with_double_dashes() {
  create_buffer_files
  bg.is_valid_long_opt "string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_long_opt_returns_1_if_string_does_not_contain_only_alphanumeric_chars_and_dashes() {
  create_buffer_files
  bg.is_valid_long_opt "--my_string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_long_opt_returns_1_if_string_ends_with_a_dash() {
  create_buffer_files
  bg.is_valid_long_opt "--mystring-" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_long_opt_returns_0_if_string_starts_with_double_dashes_and_contains_only_letters() {
  create_buffer_files
  bg.is_valid_long_opt "--string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"

}

test_is_valid_long_opt_returns_0_if_string_starts_with_double_dashes_and_contains_letters_and_numbers() {
  create_buffer_files
  bg.is_valid_long_opt "--strin4g" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"

}


test_is_valid_long_opt_returns_0_if_string_starts_with_double_dashes_and_contains_letters_numbers_and_dashes() {
  create_buffer_files
  bg.is_valid_long_opt "--string-flag2" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"

}

test_is_valid_long_opt_returns_1_if_string_starts_with_double_dashes_and_contains_a_single_letter() {
  create_buffer_files
  bg.is_valid_long_opt "--s" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"

}

test_is_valid_long_opt_returns_1_if_string_starts_with_a_single_dash() {
  create_buffer_files
  bg.is_valid_long_opt "-string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"

}

test_is_valid_long_opt_returns_1_if_string_starts_with_more_than_two_dashes() {
  create_buffer_files
  bg.is_valid_long_opt "---string-flag" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_long_opt_returns_1_if_string_is_just_two_dashes() {
  create_buffer_files
  bg.is_valid_long_opt "--" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}


test_is_valid_long_opt_returns_1_if_string_contains_more_than_one_contiguous_dash_after_the_initial_double_dashes() {
  create_buffer_files
  bg.is_valid_long_opt "--string--flag" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_short_opt_returns_0_if_string_is_a_dash_followed_by_a_letter() {
  create_buffer_files
  bg.is_valid_short_opt "-d" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_short_opt_returns_1_if_string_is_just_a_dash() {
  create_buffer_files
  bg.is_valid_short_opt "-" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_short_opt_returns_1_if_string_is_a_dash_followed_by_a_number() {
  create_buffer_files
  bg.is_valid_short_opt "-1" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_short_opt_returns_1_if_string_is_a_dash_followed_by_two_letters() {
  create_buffer_files
  bg.is_valid_short_opt "-no" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_valid_short_opt_returns_1_if_string_is_a_long_option() {
  create_buffer_files
  bg.is_valid_short_opt "--n" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_is_var_readonly_returns_1_if_variable_is_unset() {
  create_buffer_files
  bg.is_var_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_is_var_readonly_returns_1_if_variable_is_set_but_not_readonly() {
  create_buffer_files
  declare myvar
  bg.is_var_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_is_var_readonly_returns_0_if_variable_is_readonly() {
  create_buffer_files
  declare -r myvar
  bg.is_var_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_is_var_readonly_returns_0_if_variable_is_readonly_and_has_other_attributes() {
  create_buffer_files
  declare -ra myvar
  bg.is_var_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_to_array_returns_1_if_given_string_is_not_a_valid_var_name() {
  create_buffer_files

  bg.is_valid_var_name() {
    return 1 
  }
  
  bg.to_array 'string' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: 'string' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_to_array_returns_1_if_given_variable_is_readonly() {
  create_buffer_files

  declare -r myarray
  
  bg.to_array 'myarray' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: 'myarray' is a readonly variable" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_to_array_stores_a_single_line_from_stdin_into_new_array_array_name() {
  create_buffer_files
  bg.to_array myarray >"$stdout_file" 2>"$stderr_file" <<<'just a line'
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"

  # myarray should have exactly one element
  assert_equals "1" "${#myarray[@]}" "myarray should have 1 element"
  assert_equals "${myarray[0]}" "just a line" "element 0 should contain string 'just a line'"
}


test_to_array_stores_more_than_one_line_from_stdin_into_new_array_array_name() {
  create_buffer_files
  bg.to_array myarray >"$stdout_file" 2>"$stderr_file" \
    <<<"$(printf "%s\n %s" "line 1" "line 2")"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"

  # myarray should have exactly one element
  assert_equals "2" "${#myarray[@]}" "myarray should have 2 elements"
  assert_equals "${myarray[0]}" 'line 1' "element 0 should contain string 'line 1'"
  assert_equals "${myarray[1]}" ' line 2' "element 1 should contain string ' line 2'"
}

test_cli_init_prints_the_string_init_to_stdout() {
  create_buffer_files
  bg.cli.init >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "init" "$(< "$stdout_file" )" "stdout should contain the string 'init'"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_cli_add_opt_returns_1_if_first_arg_is_a_number() {
  create_buffer_files
  bg.cli.add_opt '2' 'flag' 'FLAG' 'flag description' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: short form '2' should be a single lowercase letter" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli.add_opt_returns_1_if_first_arg_is_more_than_one_character() {
  create_buffer_files
  bg.cli.add_opt 'fl' 'flag' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: short form 'fl' should be a single lowercase letter" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_flag_returns_1_if_long_form_is_not_a_valid_long_option() {
  create_buffer_files
  bg.is_valid_long_opt() {
    return 1
  }

  bg.cli.add_opt 'f' 'flag' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: long form 'flag' is not a valid long option" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_returns_1_if_env_var_is_not_a_valid_var_name() {
  create_buffer_files

  bg.cli.add_opt 'f' 'flag' '?' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: '?' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_returns_1_if_env_var_is_a_readonly_variable() {
  create_buffer_files
  local -r FLAG
  bg.cli.add_opt 'f' 'flag' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: 'FLAG' is a readonly variable" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_prints_all_lines_in_its_stdin_to_stdout_and_adds_flag_spec_line() {
  shopt -s lastpipe
  create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | bg.cli.add_opt 'd' 'directory' 'DIR' 'Directory that will store data' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      "%s\n %s\n%s" \
        "line 1" \
        "line 2" \
        "flag|d|directory|DIR|Directory that will store data"\
    )" \
    "$(< "$stdout_file" )" \
    "stdout should contain lines from stdin and new flag spec line"
}

test_cli_add_opt_escapes_any_pipe_characters_in_help_message() {
  shopt -s lastpipe
  create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | bg.cli.add_opt 'd' 'directory' 'DIR' 'Directory |that will | store data' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      '%s\n %s\n%s' \
        "line 1" \
        "line 2" \
        'flag|d|directory|DIR|Directory \|that will \| store data'\
    )" \
    "$(< "$stdout_file")" \
    "stdout should contain lines from stdin and new flag spec line"
}


test_cli_add_opt_escapes_any_backslash_in_help_message() {
  shopt -s lastpipe
  create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | bg.cli.add_opt 'd' 'directory' 'DIR' 'Directory \that will \ store data' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      "%s\n %s\n%s" \
        "line 1" \
        "line 2" \
        'flag|d|directory|DIR|Directory \\that will \\ store data'\
    )" \
    "$(< "$stdout_file" )" \
    "stdout should contain lines from stdin and new flag spec line"
}

test_canonicalize_args_returns_1_when_no_args_are_provided() {
  create_buffer_files 
  bg.canonicalize_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: arg1 (args_array) not provided but required" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_canonicalize_args_returns_1_when_only_one_arg_is_provided() {
  create_buffer_files 
  bg.canonicalize_args 'myarray' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: canonicalize_args requires at least one arg after 'args_array' to canonicalize" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_canonicalize_args_returns_1_when_args_array_is_not_a_valid_var_name() {
  bg.is_valid_var_name() {
    return 1
  }
  create_buffer_files 
  bg.canonicalize_args 'myarray' '-f' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: 'myarray' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_canonicalize_args_returns_1_when_args_array_is_readonly() {
  declare -ar myarray
  create_buffer_files 
  bg.canonicalize_args 'myarray' '-f' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: 'myarray' is a readonly array" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_canonicalize_args_returns_argument_as_it_is_when_only_one_short_form_option_is_provided() {
  create_buffer_files 
  bg.canonicalize_args 'myarray' '-f' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"

  assert_equals "1" "${#myarray[@]}" "myarray should have exactly one element"
  assert_equals '-f' "${myarray[0]}" "first element in myarray should be '-f'"
}

test_cli_parse_returns_1_when_spec_is_empty() {
  create_buffer_files
  printf "" \
    | bg.cli.parse "" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: argparse spec is empty" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_parse_returns_1_when_first_line_of_spec_is_not_init_command() {
  create_buffer_files
  printf 'command\n' \
    | bg.cli.parse "" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: Invalid argparse spec. Line 0: should be 'init' but was 'command'" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_require_args_returns_2_if_required_args_array_is_not_set() {
  create_buffer_files
  bg.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: require_args: 'required_args' array not found" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_require_args_returns_2_if_required_args_array_is_empty() {
  create_buffer_files
  local -a required_args=()
  bg.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: require_args: 'required_args' array is empty" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_require_args_returns_1_if_only_one_arg_is_required_and_none_are_provided() {
  create_buffer_files
  local -a required_args=( "ARG" )
  bg.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: ${FUNCNAME[0]}: argument 1 (ARG) is required but was not provided" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_require_args_returns_0_if_only_one_arg_is_required_and_its_provided() {
  create_buffer_files
  local -a required_args=( "ARG" )
  bg.require_args "val1" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "" \
    "$(< "$stderr_file")" \
    "stderr should be emtpy"
  assert_equals "val1" "$ARG" "variable 'ARG' should contain value of argument"
}

test_require_args_returns_1_if_two_args_are_required_but_only_one_is_provided() {
  create_buffer_files
  local -a required_args=( "ARG1" "ARG2" )
  bg.require_args "myvalue" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: ${FUNCNAME[0]}: argument 2 (ARG2) is required but was not provided" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_require_args_returns_0_if_two_args_are_required_and_two_args_are_provided() {
  create_buffer_files
  local -a required_args=( "ARG1" "ARG2" )
  bg.require_args "myvalue1" "myvalue2" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "" \
    "$(< "$stderr_file")" \
    "stderr should be empty"
  assert_equals "$ARG1" "myvalue1" "variable 'ARG1' should contain value of argument"
  assert_equals "$ARG2" "myvalue2" "variable 'ARG2' should contain value of argument"
}

test_require_args_returns_1_if_any_of_the_required_args_is_not_a_valid_variable_name() {
  create_buffer_files
  local -a required_args=( "var()" "ARG2" )
  bg.require_args "myvalue1 myvalue2" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: ${FUNCNAME[0]}: 'var()' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_require_args_places_args_with_spaces_in_correct_variable() {
  local var1
  local var2
  test_func(){
    local -a required_args=( "var1" "var2" )
    if ! bg.require_args "$@"; then
      return 2
    fi
  }
  create_buffer_files
  test_func "a value" "second value" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "$var1" "a value"
  assert_equals "$var2" "second value"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}

test_is_var_set_returns_0_if_a_variable_is_set() {
  create_buffer_files
  local myvar
  bg.is_var_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_is_var_set_returns_1_if_a_variable_is_unset_and_nounset_is_set() {
  create_buffer_files
  set -u
  bg.is_var_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_is_var_set_returns_1_if_a_variable_is_unset() {
  create_buffer_files
  unset myvar
  bg.is_var_set 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_is_var_set_returns_2_and_error_message_if_no_args_are_provided() {
  create_buffer_files
  unset myvar
  bg.is_var_set >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_matches '^ERROR: .*$' "$(< "$stderr_file")" "stderr should contain error messsage"
}

##########################################################################################
# Parse with one opt
##########################################################################################
parse_with_one_opt() {
  shopt -s lastpipe
  set -o pipefail
  bg.cli.init \
   | bg.cli.add_opt "f" "flag" "myflag" "help message" \
   | bg.cli.parse "$@"
}

test_cli_parse_with_one_opt_and_no_args() {
  create_buffer_files
  parse_with_one_opt >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_fail "bg.is_var_set 'myflag'" "var 'myflag' should not be set"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_cli_parse_with_one_opt_and_one_short_arg() {
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
  create_buffer_files
  parse_with_one_opt -h >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  help_message="$( cat <<EOF
parse_with_one_opt

Usage: parse_with_one_opt [options]

-f, --flag  help message

EOF
)"
  echo "$help_message" >/dev/tty
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert "bg.is_var_set 'myflag'" "var 'myflag' should be set"
  assert_equals "" "$myflag" "'myflag' should contain an empty string"
}
