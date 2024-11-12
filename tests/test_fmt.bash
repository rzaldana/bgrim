#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "out.bash"
}


test_fmt.fmt_prints_given_string_with_specified_formatting1() {
  set -o pipefail
  tst.create_buffer_files
  __BG_FORMAT_BLACK="BLACK"
  __BG_FORMAT_BLANK="BLANK"
  __bg.fmt.fmt "BLACK" "my cool string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "BLACKmy cool stringBLANK" "$(< "$stdout_file")"
}

test_fmt.fmt_prints_given_string_with_specified_formatting2() {
  set -o pipefail
  tst.create_buffer_files
  __BG_FORMAT_BLUE="BLUE"
  __BG_FORMAT_BLANK="BLANK"
  __bg.fmt.fmt "BLUE" "my cool string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "BLUEmy cool stringBLANK" "$(< "$stdout_file")"
}

#test_fmt.fmt_returns_1_if_given_an_invalid_formatting_option() {
#  set -o pipefail
#  tst.create_buffer_files
#  __bg.fmt.fmt "INVALID" "my cool string" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code"
#  assert_equals "ERROR: 'INVALID' is not a valid formatting. Valid options are: " "$(< "$stderr_file" )"
#  assert_equals "" "$(< "$stdout_file")"
#}
