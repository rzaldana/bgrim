# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/lib:$PATH" source tst.bash

setup_suite() {
  tst.source_lib_from_root "bgrim.bash"
}


test_cli.sanitize_string_escapes_any_pipe_characters_in_help_message() {
  set -euo pipefail
  #tst.create_buffer_files
  #__bg.cli.sanitize_string "Directory |that will | store data" >"$stdout_file" 2>"$stderr_file"
  #ret_code="$?"
  #assert_equals "0" "$ret_code" "should return exit code 0"
  #assert_equals 'Directory \|that will \| store data' "$(< "$stdout_file")"
  #assert_equals "" "$(< "$stderr_file" )" "stderr should be empty"
}
