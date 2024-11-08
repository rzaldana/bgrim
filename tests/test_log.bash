# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "bgrim.bash"
}

test_cli.log_prints_message_if_env_log_level_is_lower_than_the_provided_level() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  BG_LOG_LEVEL="TRACE"
  __bg.log.log "INFO" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "[INFO ][bash_unit]: my message" "$(< "$stderr_file" )"
}

test_cli.log_prints_message_if_env_log_level_is_equal_to_the_provided_level() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  BG_LOG_LEVEL="INFO"
  __bg.log.log "INFO" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "[INFO ][bash_unit]: my message" "$(< "$stderr_file" )"
}

test_log.log_does_not_print_message_if_env_log_level_is_higher_than_the_provided_level() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  BG_LOG_LEVEL="INFO"
  __bg.log.log "TRACE" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_log.log_returns_1_if_env_log_level_is_not_valid() {
  set -uo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  BG_LOG_LEVEL="TRCE"
  __bg.log.log "INFO" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "ERROR: 'TRCE' is not a valid log level. Valid values are: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', and 'FATAL'" "$(< "$stderr_file" )"
}

test_log.log_default_env_log_level_is_fatal1() {
  set -uo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  __bg.log.log "INFO" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )"
}

test_log.log_default_env_log_level_is_fatal2() {
  set -uo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  __bg.log.log "FATAL" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "[FATAL][bash_unit]: my message" "$(< "$stderr_file" )"
}

test_log.trace_calls_internal_log_function_with_trace_level() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.log.log() {
    mock_log_level="$1"
    mock_message="$2"
  }
  bg.log.trace "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_log_level" "TRACE"
  assert_equals "$mock_message" "my message"
}

test_log.debug_calls_internal_log_function_with_debug_level() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.log.log() {
    mock_log_level="$1"
    mock_message="$2"
  }
  bg.log.debug "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_log_level" "DEBUG"
  assert_equals "$mock_message" "my message"
}

test_log.info_calls_internal_log_function_with_info_level() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.log.log() {
    mock_log_level="$1"
    mock_message="$2"
  }
  bg.log.info "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_log_level" "INFO"
  assert_equals "$mock_message" "my message"
}

test_log.warn_calls_internal_log_function_with_warn_level() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.log.log() {
    mock_log_level="$1"
    mock_message="$2"
  }
  bg.log.warn "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_log_level" "WARN"
  assert_equals "$mock_message" "my message"
}

test_log.error_calls_internal_log_function_with_error_level() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.log.log() {
    mock_log_level="$1"
    mock_message="$2"
  }
  bg.log.error "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_log_level" "ERROR"
  assert_equals "$mock_message" "my message"
}

test_log.fatal_calls_internal_log_function_with_fatal_level() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.log.log() {
    mock_log_level="$1"
    mock_message="$2"
  }
  bg.log.fatal "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  assert_equals "$mock_log_level" "FATAL"
  assert_equals "$mock_message" "my message"
}
