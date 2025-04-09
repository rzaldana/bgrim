# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  export __BG_TEST_MODE="true"
  tst.source_lib_from_root "fmt.bash"
  __BG_ERR_FORMAT='%s\n'
  BG_LOG_FORMAT='%s - %s - %s'
  BG_NO_TTY="true"
}

test_fmt.title:prints_centered_message_with_uneven_padding_for_message_with_odd_num_of_chars() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_TTY="true"
  BG_LOG_LEVEL="TRACE"
  bg.fmt.title "mytitle" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "==================================== mytitle ===================================" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )"
}

test_fmt.title:prints_centered_message_with_even_padding_for_message_with_even_num_of_chars() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_TTY="true"
  BG_LOG_LEVEL="TRACE"
  bg.fmt.title "mytitl" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "==================================== mytitl ====================================" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )"
}

test_fmt.title:prints_intact_message_if_message_is_larger_than_title_width() {
  # title width is a constant 80 chars
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_TTY="true"
  BG_LOG_LEVEL="TRACE"
  bg.fmt.title "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )"
}

test_fmt.title:prints_message_surrounded_by_spaces_if_message_length_is_max_width_minus_2() {
  # title width is a constant 80 chars
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_TTY="true"
  BG_LOG_LEVEL="TRACE"
  bg.fmt.title "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals " mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm " "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )"
}

test_fmt.title:prints_line_of_separators_if_message_is_empty() {
  # title width is a constant 80 chars
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_TTY="true"
  BG_LOG_LEVEL="TRACE"
  bg.fmt.title "" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "================================================================================" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )"
}
