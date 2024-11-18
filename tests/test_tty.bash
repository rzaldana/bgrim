#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  __BG_TEST_MODE="true"
  tst.source_lib_from_root "tty.bash"
  __BG_ERR_FORMAT='%s\n'
}


test_tty.tty_prints_given_string_with_specified_formatting1() {
  set -o pipefail
  tst.create_buffer_files
  __BG_FORMAT_BLACK="BLACK"
  __BG_FORMAT_BLANK="BLANK"
  __bg.tty.tty "black" "my cool string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "BLACKmy cool stringBLANK" "$(< "$stdout_file")"
}

test_tty.tty_prints_given_string_with_specified_formatting2() {
  set -o pipefail
  tst.create_buffer_files
  __BG_FORMAT_BLUE="BLUE"
  __BG_FORMAT_BLANK="BLANK"
  __bg.tty.tty "BLUE" "my cool string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "BLUEmy cool stringBLANK" "$(< "$stdout_file")"
}

test_tty.tty_returns_1_if_given_an_invalid_formatting_option() {
  set -o pipefail
  tst.create_buffer_files
  __bg.tty.tty "INVALID" "my cool string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_matches "'INVALID' is not a valid formatting. Valid options are: *" "$(< "$stderr_file" )"
  assert_equals "" "$(< "$stdout_file")"
}

test_tty.tty_prints_string_untouched_if_BG_NO_TTY_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_TTY="true"
  __bg.tty.tty "RED" "my string" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "my string" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_tty.black:calls_internal_tty_function_with_black_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.black "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "BLACK"
  assert_equals "$mock_message" "my message"
}

test_tty.red:calls_internal_tty_function_with_red_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.red "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "RED"
  assert_equals "$mock_message" "my message"
}

test_tty.green:calls_internal_tty_function_with_green_formatting() {
  #set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.green "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "GREEN"
  assert_equals "$mock_message" "my message"
}

test_tty.yellow:calls_internal_tty_function_with_yellow_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.green "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "GREEN"
  assert_equals "$mock_message" "my message"
}

test_tty.blue:calls_internal_tty_function_with_blue_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.blue "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "BLUE"
  assert_equals "$mock_message" "my message"
}

test_tty.magenta:calls_internal_tty_function_with_magenta_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.magenta "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "MAGENTA"
  assert_equals "$mock_message" "my message"
}

test_tty.cyan:calls_internal_tty_function_with_cyan_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.cyan "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "CYAN"
  assert_equals "$mock_message" "my message"
}

test_tty.white:calls_internal_tty_function_with_white_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.white "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "WHITE"
  assert_equals "$mock_message" "my message"
}

test_tty.bold:calls_internal_tty_function_with_bold_formatting() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.tty.tty() {
    mock_formatting="$1"
    mock_message="$2"
  }
  bg.tty.bold "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_formatting" "BOLD"
  assert_equals "$mock_message" "my message"
}
