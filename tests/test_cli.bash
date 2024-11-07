# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "cli.bash"
}


test_cli.sanitize_string_escapes_any_pipe_characters_in_help_message() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.cli.sanitize_string "Directory |that will | store data" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals 'Directory \|that will \| store data' "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_cli_init_prints_the_string_init_to_stdout() {
  set -euo pipefail
  tst.create_buffer_files
  bg.cli.init >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "init" "$(< "$stdout_file" )" "stdout should contain the string 'init'"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_cli.stdin_to_stdout:reads_all_lines_from_stdin_and_prints_them_to_stdout() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | __bg.cli.stdin_to_stdout >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      "%s\n %s\n" \
        "line 1" \
        "line 2" \
    )" \
    "$(< "$stdout_file" )" \
    "stdout should contain lines from stdin and new opt spec line"
    assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_cli.sanitize_string_escapes_any_backlash_in_help_message() {
  set -euo pipefail
  tst.create_buffer_files
  __bg.cli.sanitize_string 'Directory \that will \ store data' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals 'Directory \\that will \\ store data' "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}

test_cli.add_opt:returns_1_if_first_arg_is_a_number() {
  tst.create_buffer_files
  bg.cli.add_opt '2' 'FLAG' 'flag description' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: option letter '2' should be a single lowercase letter" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli.add_opt:returns_1_if_first_arg_is_more_than_one_character() {
  tst.create_buffer_files
  bg.cli.add_opt 'fl' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: option letter 'fl' should be a single lowercase letter" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli.add_opt:returns_1_if_env_var_is_not_a_valid_var_name() {
  tst.create_buffer_files

  bg.cli.add_opt 'f' '?' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: '?' is not a valid variable name" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli.add_opt:returns_1_if_env_var_is_a_readonly_variable() {
  tst.create_buffer_files
  local -r FLAG
  bg.cli.add_opt 'f' 'FLAG' 'flag description'\
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: 'FLAG' is a readonly variable" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}

test_cli.add_opt:calls_cli.stdin_to_stdout_before_adding_its_own_spec_line() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files
  {
    echo "line 1" 
    echo " line 2" 
  } | bg.cli.add_opt 'd' 'DIR' 'Directory that will store data' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      "%s\n %s\n%s" \
        "line 1" \
        "line 2" \
        "opt|d|DIR|Directory that will store data"\
    )" \
    "$(< "$stdout_file" )" \
    "stdout should contain lines from stdin and new opt spec line"
}


test_cli.add_opt:sanitizes_help_message() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files

  __bg.cli.sanitize_string() {
    printf "%s" "sanitized $1"
  }
  {
    echo "line 1" 
    echo " line 2" 
  } | bg.cli.add_opt 'd' 'DIR' 'message' \
    >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals \
    "$(printf \
      '%s\n %s\n%s' \
        "line 1" \
        "line 2" \
        'opt|d|DIR|sanitized message'\
    )" \
    "$(< "$stdout_file")" \
    "stdout should contain lines from stdin and new flag spec line"
}

test_cli.add_description:calls_stdin_to_stdout_before_adding_its_own_spec_line() {
  set -o pipefail
  shopt -s lastpipe
  tst.create_buffer_files

  {
    echo "line1" 
    echo "line2"
  } | bg.cli.add_description "my description" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "$(printf "%s\n%s\n%s\n" "line1" "line2" "desc|my description")" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}

test_cli.add_description:sanitizes_description_string() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files

  __bg.cli.sanitize_string() {
    printf "%s" "sanitized $1"
  }

  {
    echo "line1" 
    echo "line2"
  } | bg.cli.add_description "my description" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "$(printf "%s\n%s\n%s\n" "line1" "line2" "desc|sanitized my description")" "$(< "$stdout_file")"
  assert_equals "" "$(< "$stderr_file")"
}

test_cli.add_arg:returns_1_if_first_arg_is_not_a_valid_variable_name() {
  set -uo pipefail
  tst.create_buffer_files

  bg.cli.add_arg '%arg' >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code"
  assert_equals "" "$(< "$stdout_file" )"
  assert_equals "ERROR: '%arg' is not a valid variable name" "$(< "$stderr_file" )"
}

test_cli.add_arg:calls_cli.stdin_to_stdout_before_adding_its_own_spec_line() {
  set -euo pipefail
  shopt -s lastpipe
  tst.create_buffer_files
  {
    echo "line1"
    echo "line2"
  } | bg.cli.add_arg "MYARG" >"$stdout_file" "$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code"
  assert_equals "" "$(< "$stderr_file" )"
  assert_equals "$(printf '%s\n%s\n%s\n' "line1" "line2" "arg|MYARG")" "$(< "$stdout_file" )"
}

#test_canonicalize_separates_arguments_from_short_options_provided_as_one_word() {
#  set -euo pipefail
#  tst.create_buffer_files
#  local -a inputs=( "option1" "-parg" "-c" "--an-option" "an arg" "-emyarg" "-d" )
#  local -a outputs
#  local -a expected_outputs=( "option1" "-p" "arg" "-c" "--an-option" "an arg" "-e" "myarg" "-d" )
#  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should exit with code 0"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#  local -i outputs_length="${#outputs[@]}"
#  assert_equals "${#expected_outputs[@]}" "$outputs_length" "outputs array should have 3 items"
#  for ((i=0; i<outputs_length; i++)); do
#    assert_equals "${expected_outputs[i]}" "${outputs[i]}"
#  done
#}
#
#
#test_canonicalize_separates_arguments_from_long_options_provided_as_one_word() {
#  set -euo pipefail
#  tst.create_buffer_files
#  local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
#  local -a outputs
#  local -a expected_outputs=( "option1" "--my-option" "myarg" "--another-opt" "another arg" )
#  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should exit with code 0"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
#  local -i outputs_length="${#outputs[@]}"
#  assert_equals "${#expected_outputs[@]}" "$outputs_length" "outputs array should have 3 items"
#  for ((i=0; i<outputs_length; i++)); do
#    assert_equals "${expected_outputs[i]}" "${outputs[i]}"
#  done
#}
#
#test_canonicalize_returns_error_if_inputs_array_does_not_exist() {
#  set -uo pipefail
#  tst.create_buffer_files
#  #local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
#  local -a outputs=( "1" "2" "3" )
#  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should exit with code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals \
#    "ERROR: array 'inputs' not found in execution environment" \
#    "$(< "$stderr_file" )" \
#    "stderr should contain error message"
#  
#  # Outputs array should be empty 
#  assert_equals "0" "${#outputs[@]}" "outputs array should be empty"
#}
#
#test_canonicalize_returns_error_if_outputs_array_is_not_valid_var_name() {
#  set -uo pipefail
#  tst.create_buffer_files
#  local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
#  _cli.canonicalize_opts 'inputs' 'outputs=' >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should exit with code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals \
#    "ERROR: 'outputs=' is not a valid variable name" \
#    "$(< "$stderr_file")" \
#    "stderr should contain error message"
#}
#
#test_canonicalize_returns_error_if_outputs_array_is_readonly() {
#  set -uo pipefail
#  tst.create_buffer_files
#  #local -a inputs=( "option1" "--my-option=myarg" "--another-opt=another arg" )
#  local -a outputs
#  local -ra outputs=( "1" "2" "3" )
#  _cli.canonicalize_opts 'inputs' 'outputs' >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should exit with code 1"
#  assert_equals "" "$(< "$stdout_file" )" "stdout should be empty"
#  assert_equals \
#    "ERROR: 'outputs' is a readonly variable" \
#    "$(< "$stderr_file" )" \
#    "stderr should contain error message"
#}

test_cli_parse_returns_1_when_spec_is_empty() {
  tst.create_buffer_files
  printf "" \
    | bg.cli.parse "" >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals \
    "ERROR: argparse spec is empty" \
    "$(< "$stderr_file")" \
    "stderr should contain error message"
}


#test_cli_parse_returns_1_when_first_line_of_spec_is_not_init_command() {
#  tst.create_buffer_files
#  printf 'command\n' \
#    | cli.parse "" >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "1" "$ret_code" "should return exit code 1"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals \
#    "ERROR: Invalid argparse spec. Line 0: should be 'init' but was 'command'" \
#    "$(< "$stderr_file")" \
#    "stderr should contain error message"
#}
#
#
###########################################################################################
## Parse with one opt
###########################################################################################
parse_with_one_opt() {
  bg.cli.parse "$@" < <(
    bg.cli.init \
      | bg.cli.add_opt "f" "myflag" "help message"
  )
}

test_cli.parse:parse_with_one_opt_help_message() {
  tst.create_buffer_files
  parse_with_one_opt -h >"$stdout_file" 2>"$stderr_file"
 ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  local expected_help_message=""
  IFS= read -d '' expected_help_message << EOF || true 
parse_with_one_opt

Usage: parse_with_one_opt [OPTIONS]

Options:
  -f help message
EOF
  assert_equals "$( printf '%s' "$expected_help_message")" "$(< "$stderr_file")" "stderr should contain an error message"
  #assert_equals "$expected_help_message" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli.parse:parse_with_one_opt1() {
  set -euo pipefail
  tst.create_buffer_files
  parse_with_one_opt >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert_fail "bg.var.is_declared 'myflag'" "var 'myflag' should not be set"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}

test_cli.parse:parse_with_one_opt2() {
  set -euo pipefail
  tst.create_buffer_files
  parse_with_one_opt -f >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "0" "$ret_code" "should return exit code 0"
  assert "bg.var.is_declared 'myflag'" "var 'myflag' should be set"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
}


test_cli.parse:parse_with_one_opt3() {
  tst.create_buffer_files
  parse_with_one_opt -g >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
  assert_fail "bg.var.is_declared 'myflag'" "var 'myflag' should not be set"
}

test_cli.parse:parse_with_one_opt4() {
  tst.create_buffer_files
  parse_with_one_opt -f -g >"$stdout_file" 2>"$stderr_file"
  ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
 assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli.parse:parse_with_one_opt5() {
  tst.create_buffer_files
  parse_with_one_opt -g -f >"$stdout_file" 2>"$stderr_file"
 ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: '-g' is not a valid option" "$(< "$stderr_file")" "stderr should contain an error message"
}

test_cli.parse:parse_with_one_opt5() {
  tst.create_buffer_files
  parse_with_one_opt -f arg >"$stdout_file" 2>"$stderr_file"
 ret_code="$?"
  assert_equals "1" "$ret_code" "should return exit code 1"
  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
  assert_equals "ERROR: Unexpected command line argument: 'arg'" "$(< "$stderr_file")" "stderr should contain an error message"
}

#test_cli_parse_with_one_opt_and_one_arg_with_opt() {
#  set -euo pipefail
#  tst.create_buffer_files
#  parse_with_one_opt -f 'myarg' >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
#  assert "bg.var.is_declared 'myflag'" "var 'myflag' should be set"
#  assert_equals "" "$myflag" "'myflag' should contain an empty string"
#}
#
#test_cli_parse_with_one_opt_prints_help() {
#  set -euo pipefail
#  tst.create_buffer_files
#  parse_with_one_opt -h >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  local help_message
#  IFS= read -d '' help_message <<EOF || true
#parse_with_one_opt
#
#Usage: parse_with_one_opt [options]
#
#-f, --flag help message
#EOF
#
#  assert_equals "0" "$ret_code" "should return exit code 0"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "$( printf "%s" "${help_message}")" \
#    "$(< "$stderr_file")" "stderr should contain help message"
#  assert_fail "bg.var.is_declared 'myflag'" "var 'myflag' should NOT be set"
#  #assert_equals "" "$myflag" "'myflag' should contain an empty string"
#}
#
###########################################################################################
## Parse with one opt with arg
###########################################################################################
#parse_with_one_opt_with_arg() {
#  cli.parse "$@" < <(
#    cli.init \
#      | cli.add_opt_with_arg "f" "flag" "myflag" "help message"
#  )
#}
#
#test_cli_parse_with_one_opt_with_arg_and_no_args() {
#  set -euo pipefail
#  tst.create_buffer_files
#  parse_with_one_opt_with_arg >"$stdout_file" 2>"$stderr_file"
#  ret_code="$?"
#  assert_equals "0" "$ret_code" "should return exit code 0"
#  assert_fail "bg.var.is_declared 'myflag'" "var 'myflag' should not be set"
#  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
#  assert_equals "" "$(< "$stderr_file")" "stderr should be empty"
#}
#
##test_cli_parse_with_one_opt_with_arg_and_one_short_arg() {
##  set -euo pipefail
##  tst.create_buffer_files
##  parse_with_one_opt -f >"$stdout_file" 2>"$stderr_file"
##  ret_code="$?"
##  assert_equals "1" "$ret_code" "should return exit code 1"
##  assert_fail "bg.var.is_declared 'myflag'" "var 'myflag' should not be set"
##  assert_equals "" "$(< "$stdout_file")" "stdout should be empty"
##  assert_equals "ERROR: option '-f' requires an argument" "$(< "$stderr_file")" "stderr should contain an error message"
##}
