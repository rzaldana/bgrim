#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "bgrim.bash"
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

test_trap.add_can_set_two_traps() {
  ./test_scripts/trap.bash
}
