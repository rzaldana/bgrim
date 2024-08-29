# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "cli.bash"
}

test_cli_init_prints_the_string_init_to_stdout() {
  set -euo pipefail
  tst.create_buffer_files
  cli.init >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "init" "$(< "$stdout_file" )" "stdout should contain the string 'init'"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_cli_add_opt_returns_1_if_first_arg_is_a_number() {
  tst.create_buffer_files
  cli.add_opt '2' 'flag' 'FLAG' 'flag description' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: short form '2' should be a single lowercase letter" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli.add_opt_returns_1_if_first_arg_is_more_than_one_character() {
  tst.create_buffer_files
  cli.add_opt 'fl' 'flag' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: short form 'fl' should be a single lowercase letter" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_flag_returns_1_if_long_form_is_not_a_valid_long_option() {
  tst.create_buffer_files
  core.is_valid_long_opt() {
    return 1
  }

  cli.add_opt 'f' 'flag' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: long form 'flag' is not a valid long option" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_returns_1_if_env_var_is_not_a_valid_var_name() {
  tst.create_buffer_files

  cli.add_opt 'f' 'flag' '?' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: '?' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_returns_1_if_env_var_is_a_readonly_variable() {
  tst.create_buffer_files
  local -r FLAG
  cli.add_opt 'f' 'flag' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: 'FLAG' is a readonly variable" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_add_opt_prints_all_lines_in_its_stdin_to_stdout_and_adds_flag_spec_line() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | cli.add_opt 'd' 'directory' 'DIR' 'Directory that will store data' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      "%s\n %s\n%s" \
        "line 1" \
        "line 2" \
        "flag|d|directory|DIR|Directory that will store data"\
    )" \
    "$(< "$stdout_file" )" \
    "stdout should contain lines from stdin and new flag spec line"
}

test_cli_add_opt_escapes_any_pipe_characters_in_help_message() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | cli.add_opt 'd' 'directory' 'DIR' 'Directory |that will | store data' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      '%s\n %s\n%s' \
        "line 1" \
        "line 2" \
        'flag|d|directory|DIR|Directory \|that will \| store data'\
    )" \
    "$(< "$stdout_file")" \
    "stdout should contain lines from stdin and new flag spec line"
}


test_cli_add_opt_escapes_any_backslash_in_help_message() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | cli.add_opt 'd' 'directory' 'DIR' 'Directory \that will \ store data' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      "%s\n %s\n%s" \
        "line 1" \
        "line 2" \
        'flag|d|directory|DIR|Directory \\that will \\ store data'\
    )" \
    "$(< "$stdout_file" )" \
    "stdout should contain lines from stdin and new flag spec line"
}


test_canonicalize_separates_arguments_from_short_options_provided_as_one_word() {
  set -euo pipefail
  tst.create_buffer_files
  local -a inputs=( "option1" "-parg" "-c" "--an-option" "an arg" "-emyarg" "-d" )
  local -a outputs
  local -a expected_outputs=( "option1" "-p" "arg" "-c" "--an-option" "an arg" "-e" "myarg" "-d" )
  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should exit with code 0"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  local -i outputs_length="${#outputs[@]}"
  assert_equals "${#expected_outputs[@]}" "$outputs_length" "outputs array should have 3 items"
  for ((i=0; i<outputs_length; i++)); do
    assert_equals "${expected_outputs[i]}" "${outputs[i]}"
  done
}


test_canonicalize_separates_arguments_from_long_options_provided_as_one_word() {
  set -euo pipefail
  tst.create_buffer_files
  local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
  local -a outputs
  local -a expected_outputs=( "option1" "--my-option" "myarg" "--another-opt" "another arg" )
  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should exit with code 0"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
  local -i outputs_length="${#outputs[@]}"
  assert_equals "${#expected_outputs[@]}" "$outputs_length" "outputs array should have 3 items"
  for ((i=0; i<outputs_length; i++)); do
    assert_equals "${expected_outputs[i]}" "${outputs[i]}"
  done
}

test_canonicalize_returns_error_if_inputs_array_does_not_exist() {
  set -uo pipefail
  tst.create_buffer_files
  #local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
  local -a outputs=( "1" "2" "3" )
  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should exit with code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "ERROR: array 'inputs' not found in execution environment" \
    "$(< "$stderr_file" )" \
    "stderr should contain error message"
  
  # Outputs array should be empty 
  assert_equals "0" "${#outputs[@]}" "outputs array should be empty"
}

test_canonicalize_returns_error_if_outputs_array_is_not_valid_var_name() {
  set -uo pipefail
  tst.create_buffer_files
  local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
  _cli.canonicalize_opts 'inputs' 'outputs=' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should exit with code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "ERROR: 'outputs=' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_canonicalize_returns_error_if_outputs_array_is_readonly() {
  set -uo pipefail
  tst.create_buffer_files
  #local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
  local -a outputs
  local -ra outputs=( "1" "2" "3" )
  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should exit with code 1"
  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
  assert_equals \
    "ERROR: 'outputs' is a readonly variable" \
    "$(< "$stderr_file" )" \
    "stderr should contain error message"
}

test_cli_parse_returns_1_when_spec_is_empty() {
  tst.create_buffer_files
  printf "" \
    | cli.parse "" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: argparse spec is empty" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli_parse_returns_1_when_first_line_of_spec_is_not_init_command() {
  tst.create_buffer_files
  printf 'command\n' \
    | cli.parse "" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: Invalid argparse spec. Line 0: should be 'init' but was 'command'" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}


##########################################################################################
# Parse with one opt
##########################################################################################
parse_with_one_opt() {
  cli.parse "$@" < <(
    cli.init \
      | cli.add_opt "f" "flag" "myflag" "help message"
  )
}

test_cli_parse_with_one_opt_and_no_args() {
  set -euo pipefail
  tst.create_buffer_files
  parse_with_one_opt >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_fail "core.is_var_set 'myflag'" "var 'myflag' should not be set"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_cli_parse_with_one_opt_and_one_short_arg() {
  set -euo pipefail
  tst.create_buffer_files
  parse_with_one_opt -f >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert "core.is_var_set 'myflag'" "var 'myflag' should be set"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}


test_cli_parse_with_one_opt_and_invalid_opt() {
  tst.create_buffer_files
  parse_with_one_opt -g >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
  assert_fail "core.is_var_set 'myflag'" "var 'myflag' should not be set"
}

test_cli_parse_with_one_opt_and_invalid_long_arg() {
  tst.create_buffer_files
  parse_with_one_opt --invalid >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '--invalid' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
  assert_fail "core.is_var_set 'myflag'" "var 'myflag' should not be set"
}


test_cli_parse_with_one_opt_and_valid_with_invalid_opt1() {
  tst.create_buffer_files
  parse_with_one_opt -f -g >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli_parse_with_one_opt_and_valid_with_invalid_opt2() {
  tst.create_buffer_files
  parse_with_one_opt -g -f >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}


test_cli_parse_with_one_opt_and_valid_with_invalid_opt3() {
  tst.create_buffer_files
  parse_with_one_opt -g --flag >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli_parse_with_one_opt_and_valid_with_invalid_opt4() {
  tst.create_buffer_files
  parse_with_one_opt --invalid -f >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '--invalid' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli_parse_with_one_opt_and_one_arg_with_opt() {
  set -euo pipefail
  tst.create_buffer_files
  parse_with_one_opt -f 'myarg' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
  assert "core.is_var_set 'myflag'" "var 'myflag' should be set"
  assert_equals "" "$myflag" "'myflag' should contain an empty string"
}

test_cli_parse_with_one_opt_prints_help() {
  set -euo pipefail
  tst.create_buffer_files
  parse_with_one_opt -h >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  local help_message
  IFS= read -d '' help_message <<EOF || true
parse_with_one_opt

Usage: parse_with_one_opt [options]

-f, --flag help message
EOF

  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "$( printf "%s" "${help_message}")" \
    "$(< "$stderr_file")" "stderr should contain help message"
  assert_fail "core.is_var_set 'myflag'" "var 'myflag' should NOT be set"
  #assert_equals "" "$myflag" "'myflag' should contain an empty string"
}


