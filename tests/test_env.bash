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
