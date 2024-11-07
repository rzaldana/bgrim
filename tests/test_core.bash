#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "core.bash"
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
    "ERROR: bg.str.is_valid_var_name: argument 1 (var_name) is required but was not provided" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
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

test_trap.clear_all_clears_all_traps_set_in_the_current_and_parent_environment() {
  set -euo pipefail
  stderr_file="$(mktemp)"
  func_stdout_file="$(mktemp)"
  total_stdout_file="$(mktemp)"
  ret_code_file="$(mktemp)"

  # Cleanup stderr and stdout files on exit
  tst.rm_on_exit "$stderr_file" "$func_stdout_file" "$ret_code_file" "$total_stdout_file"

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

    bg.trap.clear_all >"$func_stdout_file" #|| echo "failed!" >/dev/tty
    echo "$?" > "$ret_code_file" || echo "failed to write!" >/dev/tty

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
  assert_equals "ERROR: '*' is not a valid variable prefix" "$(< "$stderr_file")"
  assert_equals "my value" "${PREFIX_MY_VAR:-}" "PREFIX_MY_VAR should be empty"
  assert_equals "env value" "${PREFIX_ENV_VAR:-}" "PREFIX_ENV_VAR should be empty"
  assert_equals "local value" "${PREFIX_LOCAL_VAR:-}" "PREFIX_LOCAL_VAR should be empty"

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

test_arr.is_member_returns_0_when_the_given_value_is_in_the_array_with_the_given_name() {
  set -euo pipefail
  local -a test_array=( "val1" "val2" "val3" ) 
  stdout_and_stderr="$(bg.arr.is_member "test_array" "val2" 2>&1)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "function call should return 0 when value is present in array with given name"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_arr.is_member_returns_1_when_the_given_value_is_not_in_the_array_with_the_given_name() {
  local -a test_array=( "val1" "val2" "val3" ) 
  stdout_and_stderr="$(bg.arr.is_member "test_array" "val4" 2>&1)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "function call should return 1 when value is not present in array with given name"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_func.is_declared_returns_0_when_given_the_name_of_a_function_in_the_env() {
  set -euo pipefail
  local stdout_and_stderr

  # shellcheck disable=SC2317
  test_fn() {
    echo "test" 
  }

  stdout_and_stderr="$(bg.func.is_declared test_fn)"
  ret_code="$?"
  assert_equals "0" "$ret_code" "is_function should return 0 when the given fn is defined"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
}

test_func.is_declared_returns_1_when_the_given_name_does_not_refer_to_a_function() {
  local stdout_and_stderr
  local test_fn

  stdout_and_stderr="$(bg.func.is_declared test_fn)"
  ret_code="$?"
  assert_equals "1" "$ret_code" "is_function should return 1 when the given fn is not defined"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
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


test_trap.get_returns_nothing_if_given_a_signal_that_does_not_have_a_trap() {
  set -euo pipefail
  local stdout_and_stderr
  stdout_and_stderr="$( 
  # Clear SIGINT trap
  trap - SIGINT 

  # Call function
  bg.trap.get 'SIGINT' 2>&1 
  )"

  ret_code="$?"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0 when trap is not set"
}

test_trap.get_returns_nothing_if_given_a_signal_with_an_ignore_trap() {
  set -euo pipefail
  local stdout_and_stderr
  stdout_and_stderr="$( 
  # Clear SIGINT trap
  trap '' SIGINT 

  # Call function
  bg.trap.get 'SIGINT' 2>&1 
  )"

  ret_code="$?"
  assert_equals "" "$stdout_and_stderr" "stdout and stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0 when trap is not set"
}

test_trap.get_returns_trap_command_if_given_a_signal_that_has_a_trap() {
  set -euo pipefail
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file"
  # Set SIGINT trap
  trap "$(cat <<HERE
echo hello
echo bye
HERE
)" SIGINT 

  stdout="$( 
    # Call function
    bg.trap.get 'SIGINT' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals $'echo hello\necho bye' "$stdout" "stdout should return trap command"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0 when trap is not set"
}


test_trap.get_returns_1_and_error_code_if_there_is_an_error_while_retrieving_the_trap() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  fake_trap() {
    echo "An Error occurred!" >&2
    return 1
  }

  fake trap fake_trap

  stdout="$( 
    # Call function
    bg.trap.get 'MYSIG' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals 'Error retrieving trap for signal '\''MYSIG'\''. Error message: '\''An Error occurred!'\''' "$(< "$stderr_file")" "stderr should contain an error message"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}

test_trap.add_sets_a_trap_if_the_signal_spec_is_ignored() {
  set -euo pipefail
  local stdout_file
  local stderr_file
  local traps_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  traps_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file" "$stdout_file" "$traps_file"

  # Ignore trap
  trap '' SIGINT
 
  # Use function to set trap 
  bg.trap.add "echo hello" SIGINT 1>"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  
  # Get list of traps for SIGINT
  trap -p SIGINT >"$traps_file"

  assert_equals "0" "$ret_code" "return code should be 0 if the trap was added"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "trap -- 'echo hello' SIGINT" "$(< "$traps_file")" "SIGINT trap should contain 'echo hello'"
}


test_trap.add_sets_a_trap_if_the_signal_spec_doesnt_have_a_trap() {
  set -euo pipefail
  local stdout_file
  local stderr_file
  local traps_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  traps_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file" "$stdout_file" "$traps_file"

  # Clear trap
  trap '-' SIGINT
 
  # Use function to set trap 
  bg.trap.add "echo hello" SIGINT 1>"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  
  # Get list of traps for SIGINT
  trap -p SIGINT >"$traps_file"

  assert_equals "0" "$ret_code" "return code should be 0 if the trap was added"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "trap -- 'echo hello' SIGINT" "$(< "$traps_file")" "SIGINT trap should contain 'echo hello'"
}

test_trap.add_adds_a_command_to_the_trap_for_an_existing_signal_if_the_signal_already_has_a_trap() {
  set -euo pipefail
  local stdout_file
  local stderr_file
  local traps_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  traps_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file" "$stdout_file" "$traps_file"

  # Clear trap
  trap - SIGINT

  # Set initial trap
  trap "echo hello" SIGINT
 
  # Use function to set second trap 
  bg.trap.add "echo goodbye" SIGINT 1>"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  
  # Get list of traps for SIGINT
  traps="$(trap -p SIGINT)"

  assert_equals "0" "$ret_code" "return code should be 0 if the trap was added"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals 'trap -- '\'$'echo hello\necho goodbye'\'' SIGINT' "$traps" "SIGINT trap should contain both commands"
}

test_trap.add_returns_1_and_error_code_if_there_is_an_error_while_retrieving_the_existing_trap() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  fake_trap.get() {
    echo "An Error occurred!" >&2
    return 1
  }

  fake bg.trap.get fake_trap.get

  stdout="$( 
    # Call function
    bg.trap.add 'command' 'MYSIG' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals "Error retrieving existing trap for signal 'MYSIG'" "$(< "$stderr_file")" "stderr should contain an error message"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}


test_trap.add_returns_1_and_error_message_if_there_is_an_error_while_setting_the_new_trap() {
  local stdout
  local stderr_file
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stderr_file"

  # shellcheck disable=SC2317
  fake_trap() {
    [[ "${FAKE_PARAMS[0]:-}" != "-p" ]]  \
      && { echo "An Error occurred!" >&2; return 1; }
    echo 'fake_trap_command'
  }

  fake trap fake_trap 

  stdout="$( 
    # Call function
    bg.trap.add 'command' 'SIGINT' 2>"$stderr_file"
  )"

  ret_code="$?"
  assert_equals "" "$stdout" "stdout should be empty"
  assert_equals "Error setting new trap for signal 'SIGINT'" "$(< "$stderr_file")"
  assert_equals "1" "$ret_code" "should return 1 when trap is not set"
}

test_tmpfile.new_fails_when_filename_var_is_not_a_valid_var_name() {
  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2016
  bg.tmpfile.new '$myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "return code should be 1 filename_var is not a valid var name"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '\$myvar' is not a valid variable name" "$(< "$stderr_file")"
}

test_trap.add_can_set_two_traps() {
  ./test_scripts/trap.bash
}

test_tmpfile.new_creates_two_temporary_files() {
  ./test_scripts/tmpfile.bash
}

test_tmpfile.new_invokes_mktemp_and_trap_function() {
  set -euo pipefail
  local stdout_file
  local stderr_file
  local tmpfile_name_file
  local trap_output_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  trap_output_file="$(mktemp)"
  tmpfile_name_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file" "$tmpfile_name_file" "$trap_output_file"

  fake_mktemp() {
    echo "test_file" >"$tmpfile_name_file"
    cat "$tmpfile_name_file"
  }

  bg.trap.add() {
    echo "1:$1" >"$trap_output_file"
    echo "2:$2" >>"$trap_output_file"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals \
    "$(printf "%s\n%s" "1:rm -f '$(< "$tmpfile_name_file")'" "2:EXIT")" \
    "$(< "$trap_output_file")"
  assert_equals "$(< "$tmpfile_name_file")" "$filename" "'filename' var should contain name of temp file"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0"
}


test_tmpfile.new_stores_tmpfilen_name_in_var_even_when_var_is_not_defined_beforehand() {
  set -euo pipefail
  local stdout_file
  local stderr_file
  local tmpfile_name_file
  local trap_output_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  trap_output_file="$(mktemp)"
  tmpfile_name_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file" "$tmpfile_name_file" "$trap_output_file"

  fake_mktemp() {
    echo "test_file" >"$tmpfile_name_file"
    cat "$tmpfile_name_file"
  }

  bg.trap.add() {
    echo "1:$1" >"$trap_output_file"
    echo "2:$2" >>"$trap_output_file"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'myfilename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals \
    "$(printf "%s\n%s" "1:rm -f '$(< "$tmpfile_name_file")'" "2:EXIT")" \
    "$(< "$trap_output_file")"
  assert_equals "$(< "$tmpfile_name_file")" "$myfilename" "'myfilename' var should contain name of temp file"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert_equals "0" "$ret_code" "should return 0"
}


test_tmpfile.new_returns_1_if_mktemp_fails() {
  local stdout_file
  local stderr_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file"

  fake_mktemp() {
    echo "ERROR!" >&2
    return 1
  }

  bg.trap.add() {
    echo "1:${1:-}"
    echo "2:${2:-}"
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "${filename:-}" "'filename' var should be empty"
  assert_equals "$(printf "%s\n%s" "ERROR!" "ERROR: Unable to create temporary file")" "$(< "$stderr_file")" "stderr should contain error message"
  assert_equals "1" "$ret_code" "should return 1"
}


test_tmpfile.new_returns_1_if_trap_fails() {
  local stdout_file
  local stderr_file
  local filename
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file"

  fake_mktemp() {
    echo "test_file"
  }

  bg.trap.add() {
    echo "ERROR!" >&2
    return 1
  }

  __BG_MKTEMP="fake_mktemp"

  bg.tmpfile.new 'filename' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "${filename:-}" "'filename' var should be empty"
  assert_equals "$(printf "%s\n%s" "ERROR!" "ERROR: Unable to set exit trap to delete file 'test_file'")" "$(< "$stderr_file")" "stderr should contain error message"
  assert_equals "1" "$ret_code" "should return 1"
}

#test_is_valid_long_opt_returns_1_if_string_does_not_start_with_double_dashes() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "string" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_long_opt_returns_1_if_string_does_not_contain_only_alphanumeric_chars_and_dashes() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "--my_string" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_long_opt_returns_1_if_string_ends_with_a_dash() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "--mystring-" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_long_opt_returns_0_if_string_starts_with_double_dashes_and_contains_only_letters() {
#  set -euo pipefail
#  tst.create_buffer_files
#  core.is_valid_long_opt "--string" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#
#}
#
#test_is_valid_long_opt_returns_0_if_string_starts_with_double_dashes_and_contains_letters_and_numbers() {
#  set -euo pipefail
#  tst.create_buffer_files
#  core.is_valid_long_opt "--strin4g" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#
#}
#
#
#test_is_valid_long_opt_returns_0_if_string_starts_with_double_dashes_and_contains_letters_numbers_and_dashes() {
#  set -euo pipefail
#  tst.create_buffer_files
#  core.is_valid_long_opt "--string-flag2" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#
#}
#
#test_is_valid_long_opt_returns_1_if_string_starts_with_double_dashes_and_contains_a_single_letter() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "--s" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#
#}
#
#test_is_valid_long_opt_returns_1_if_string_starts_with_a_single_dash() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "-string" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#
#}
#
#test_is_valid_long_opt_returns_1_if_string_starts_with_more_than_two_dashes() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "---string-flag" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_long_opt_returns_1_if_string_is_just_two_dashes() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "--" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#
#test_is_valid_long_opt_returns_1_if_string_contains_more_than_one_contiguous_dash_after_the_initial_double_dashes() {
#  tst.create_buffer_files
#  core.is_valid_long_opt "--string--flag" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}

#test_is_valid_short_opt_returns_0_if_string_is_a_dash_followed_by_a_letter() {
#  set -euo pipefail
#  tst.create_buffer_files
#  core.is_valid_short_opt "-d" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_short_opt_returns_1_if_string_is_just_a_dash() {
#  tst.create_buffer_files
#  core.is_valid_short_opt "-" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_short_opt_returns_1_if_string_is_a_dash_followed_by_a_number() {
#  tst.create_buffer_files
#  core.is_valid_short_opt "-1" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_short_opt_returns_1_if_string_is_a_dash_followed_by_two_letters() {
#  tst.create_buffer_files
#  core.is_valid_short_opt "-no" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}
#
#test_is_valid_short_opt_returns_1_if_string_is_a_long_option() {
#  tst.create_buffer_files
#  core.is_valid_short_opt "--n" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#}

test_arr.is_var_readonly_returns_1_if_variable_is_unset() {
  tst.create_buffer_files
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_arr.is_var_readonly_returns_1_if_variable_is_set_but_not_readonly() {
  tst.create_buffer_files
  declare myvar
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_arr.is_var_readonly_returns_0_if_variable_is_readonly() {
  set -euo pipefail
  tst.create_buffer_files
  declare -r myvar
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_arr.is_var_readonly_returns_0_if_variable_is_readonly_and_has_other_attributes() {
  set -euo pipefail
  tst.create_buffer_files
  declare -ra myvar
  bg.var.is_readonly 'myvar' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_arr.from_stdin_stores_a_single_line_from_stdin_into_new_array_array_name() {
  set -euo pipefail
  tst.create_buffer_files
  local -a myarray=()
  bg.arr.from_stdin myarray >"$stdout_file" 2>"$stderr_file" <<<'just a line'
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"

  # myarray should have exactly one element
  assert_equals "1" "${#myarray[@]}" "myarray should have 1 element"
  assert_equals "${myarray[0]}" "just a line" "element 0 should contain string 'just a line'"
}


test_arr.from_stdin_stores_more_than_one_line_from_stdin_into_new_array_array_name() {
  set -euo pipefail
  tst.create_buffer_files
  local -a myarray=()
  bg.arr.from_stdin myarray >"$stdout_file" 2>"$stderr_file" \
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

test_in.require_args_returns_2_if_required_args_array_is_not_set() {
  tst.create_buffer_files
  bg.in.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: require_args: 'required_args' array not found" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_2_if_required_args_array_is_empty() {
  tst.create_buffer_files
  local -a required_args=()
  bg.in.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: require_args: 'required_args' array is empty" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_returns_1_if_only_one_arg_is_required_and_none_are_provided() {
  tst.create_buffer_files
  local -a required_args=( "ARG" )
  bg.in.require_args >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: ${FUNCNAME[0]}: argument 1 (ARG) is required but was not provided" \
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
    "ERROR: ${FUNCNAME[0]}: argument 2 (ARG2) is required but was not provided" \
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
    "ERROR: ${FUNCNAME[0]}: array variable with name 'new_array' is not set" \
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
    "ERROR: ${FUNCNAME[0]}: 'var()' is not a valid variable name" \
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
    "ERROR: ${FUNCNAME[0]}: array variable with name 'nonarray' does not exist" \
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
    "ERROR: ${FUNCNAME[0]}: array variable with name 'an_array' is not set" \
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
    "ERROR: ${FUNCNAME[0]}: array variable with name 'nonarray' does not exist" \
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
    "ERROR: ${FUNCNAME[0]}: array variable with name 'an_array' is not set" \
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
    "ERROR: ${FUNCNAME[0]}: array variable with name 'another_array' is read-only" \
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
    "ERROR: ${FUNCNAME[0]}: Type prefix 'dwa' for variable 'myarray' is not valid. Valid prefixes are: 'ra' and 'rwa'" \
    "$(< "$stderr_file")" \
    "stderr should contain an error message"
}

test_in.require_args_places_args_with_spaces_in_correct_variable() {
  set -euo pipefail
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


test_var.is_declared_returns_0_if_a_variable_is_declared() {
  set -euo pipefail
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
  assert_matches '^ERROR: .*$' "$(< "$stderr_file")" "stderr should contain error messsage"
}

test_var.is_set_returns_2_and_error_message_if_no_args_are_provided() {
  tst.create_buffer_files
  unset myvar
  bg.var.is_set >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "2" "$ret_code" "should return exit code 2"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_matches '^ERROR: .*$' "$(< "$stderr_file")" "stderr should contain error messsage"
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

test_arr.index_of_returns_error_if_item_not_found_in_array() {
  set -uo pipefail
  local -a myarray=( "first" "second" "third" )
  tst.create_buffer_files
  bg.arr.index_of 'myarray' "fourth" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "ERROR: item 'fourth' not found in array with name 'myarray'" \
    "$(< "$stderr_file" )" "stderr should be empty"
}


test_arr.index_of_returns_the_index_of_the_provided_item_in_the_provided_array() {
  set -euo pipefail
  local -a myarray=( "first" "second" "third" )
  tst.create_buffer_files
  bg.arr.index_of 'myarray' "second" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "1" "$(< "$stdout_file" )" "stdout should contain '1'"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}
