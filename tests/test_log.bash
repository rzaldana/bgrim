# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  export __BG_TEST_MODE="true"
  tst.source_lib_from_root "log.bash"
  __BG_ERR_FORMAT='%s\n'
  BG_LOG_FORMAT='%s - %s - %s'
  BG_NO_FORMAT="true"
}

test_log.log:prints_message_if_env_log_level_is_lower_than_the_provided_level() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  BG_LOG_LEVEL="TRACE"
  __bg.log.log "INFO" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "bash_unit - INFO - my message" "$(< "$stderr_file" )"
}

test_log.log:prints_message_if_env_log_level_is_equal_to_the_provided_level() {
  #set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  BG_LOG_LEVEL="INFO"
  __bg.log.log "INFO" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "bash_unit - INFO - my message" "$(< "$stderr_file" )"
}

test_log.log:does_not_print_message_if_env_log_level_is_higher_than_the_provided_level() {
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

test_log.log:uses_default_log_format_if_no_log_format_is_provided() {
  set -euo pipefail
  tst.create_buffer_files
  BG_NO_FORMAT="true"
  BG_LOG_LEVEL="TRACE"
  unset BG_LOG_FORMAT
  __BG_LOG_DEFAULT_FORMAT="%s/%s/%s\n"
  __bg.log.log "INFO" "my message" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "bash_unit/INFO/my message" "$(< "$stderr_file" )"
}

test_log.log:prints_logs_to_file_if_log_out_is_provided_with_file() {
  tst.create_buffer_files
  BG_LOG_OUT="$stdout_file"
  BG_LOG_LEVEL="TRACE"
  set -euo pipefail
  local stdout_and_stderr
  stdout_and_stderr="$(__bg.log.log "INFO" "my message" 2>&1 )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
  assert_equals "bash_unit - INFO - my message" "$(< "$stdout_file")"
}

test_log.log:prints_logs_to_fd_if_log_out_is_provided_with_fd() {
  tst.create_buffer_files
  BG_LOG_OUT="&3"
  BG_LOG_LEVEL="TRACE"
  set -euo pipefail
  local stdout_and_stderr
  stdout_and_stderr="$(\
    __bg.log.log \
      "INFO" \
       "my message" 2>&1 3>"$stdout_file" 
  )"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$stdout_and_stderr"
  assert_equals "bash_unit - INFO - my message" "$(< "$stdout_file")"
}

test_log.log:prints_logs_to_default_out_if_no_log_out_is_provided() {
  tst.create_buffer_files
  unset BG_LOG_OUT
  __BG_LOG_DEFAULT_OUT="&3"
  BG_LOG_LEVEL="TRACE"
  set -euo pipefail
  local stdout_and_stderr
  __bg.log.log "INFO" "my message" 2>&1 >"$stdout_file" 3>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stdout_file")"
  assert_equals "bash_unit - INFO - my message" "$(< "$stderr_file")"
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
  assert_equals "'TRCE' is not a valid log level. Valid values are: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', and 'FATAL'" "$(< "$stderr_file" )"
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
  assert_equals "bash_unit - FATAL - my message" "$(< "$stderr_file" )"
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
