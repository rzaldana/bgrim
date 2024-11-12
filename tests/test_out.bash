#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "bgrim.bash"
}

test_out.format_black_prints_the_given_string_in_red() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_BLACK="BLACK"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_black "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "BLACKmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_black_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_black "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_red_prints_the_given_string_in_red() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_RED="RED"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_red "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "REDmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_red_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_red "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_green_prints_the_given_string_in_green() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_GREEN="GREEN"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_green "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "GREENmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_green_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_green "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_yellow_prints_the_given_string_in_yellow() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_YELLOW="YELLOW"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_yellow "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "YELLOWmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_yellow_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_yellow "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_blue_prints_the_given_string_in_blue() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_BLUE="BLUE"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_blue "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "BLUEmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_blue_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_blue "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_magenta_prints_the_given_string_in_magenta() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_MAGENTA="MAGENTA"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_magenta "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "MAGENTAmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_magenta_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_magenta "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_cyan_prints_the_given_string_in_cyan() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_CYAN="CYAN"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_cyan "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "CYANmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_cyan_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_cyan "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_white_prints_the_given_string_in_white() {
  set -euo pipefail
  tst.create_buffer_files
  __BG_FORMAT_WHITE="WHITE"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_white "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "WHITEmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_white_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_white "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}

test_out.format_bold_prints_the_given_string_in_bold() {
  set -o pipefail
  tst.create_buffer_files
  __BG_FORMAT_BOLD="BOLD"
  __BG_FORMAT_BLANK="BLANK"
  bg.out.format_bold "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "BOLDmy cool stringBLANK" "$(< "$stdout_file" )"
}

test_out.format_bold_prints_the_given_string_with_no_format_code_if_no_format_env_var_is_set() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT=""
  bg.out.format_bold "my cool string" 2>"$stderr_file" >"$stdout_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "my cool string" "$(< "$stdout_file" )"
}
