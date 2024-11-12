#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "arr.bash"
  __BG_ERR_FORMAT="%s\n"
}

test_arr.length:returns_length_of_array_if_array_is_empty() {
  set -euo pipefail
  local -a test_arr=()
  tst.create_buffer_files
  bg.arr.length 'test_arr' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "0" "$(< "$stdout_file")" "stdout should be 0"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_arr.length:returns_length_of_array_if_array_has_items() {
  set -euo pipefail
  local -a test_arr=( "item1" "item2" "item3" )
  tst.create_buffer_files
  bg.arr.length 'test_arr' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "3" "$(< "$stdout_file")" "stdout should be 0"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
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

test_arr.index_of_returns_error_if_item_not_found_in_array() {
  set -uo pipefail
  local -a myarray=( "first" "second" "third" )
  tst.create_buffer_files
  bg.arr.index_of 'myarray' "fourth" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "item 'fourth' not found in array with name 'myarray'" \
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

#test_arr.verbalize_prints_nothing_if_given_an_empty_array() {
#  set -euo pipefail
#  local -a myarray=()
#  tst.create_buffer_files
#  bg.arr.verbalize 'myarray'
#  ret_code="$?"
#  assert_equals "0" "$ret_code"
#  assert_equals "" "$(< "$stdout_file")"
#  assert_equals "" "$(< "$stderr_file")"
#}
