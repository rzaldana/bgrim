#!/usr/bin/env bash

################################################################################
# description: |
#   creates a trap that will delete the given filenames when the 
#   current shell exits. This only works here because bash_unit runs each
#   unit test function in a separate subshell, so any execute trap declared 
#   within a test will execute when the subshell exits, i.e., when the test
#   is finished running. The command can only be used once for each test. 
#   Subsequent calls will overwrite previous traps.
# inputs:
#   stdin:
#   args:
# outputs:
#   stdout:
#   stderr:
#   return_code:
# Returns:
#   0: if the first argument is missing or an empty string 
#   1: otherwise
################################################################################
tst.rm_on_exit() {
  # Check that at least one arg was provided
  [[ "$#" -gt 0 ]] || { echo "rm_on_exit: No file names were provided" >/dev/tty; return 1; }

  # shellcheck disable=SC2317 
  cleanup_fn() {
    # Change permissions
    for file in "$@"; do
      chmod 0500 "$file"
    done

    # Remove file
    rm_output="$(rm -rf "$@" 2>&1)" \
      || { echo "Unable to remove temporary file. Output from 'rm':  $rm_output" >&2; return 1; }
  }

  # shellcheck disable=SC2064
  trap "cleanup_fn $*" EXIT
}

tst.create_buffer_files() {
  # stderr_file and stdout_file are NOT
  # local because we want to leave the
  # file names accessible in the function's
  # parent
  stderr_file="$(mktemp)"  
  stdout_file="$(mktemp)"
  tst.rm_on_exit "$stdout_file" "$stderr_file"
}

tst.get_repo_root() {

  # Find the absolute path of the directory where the current 
  # script is
  local current_dir
  current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


  # Traverse up the directory tree
  while [[ "$current_dir" != "/" ]]; do
    if [[ -d "$current_dir/.git" ]]; then
      printf '%s' "$current_dir"
      return 0
    fi

    # Move up one directory
    current_dir="$(dirname "$current_dir")"
  done
  
  printf 'ERROR: could not find root of repository'
  return 1
}

tst.source_lib_from_root() {
  # Check that at least one arg was provided
  [[ "$#" -gt 0 ]] || { echo "tst.source_lib_from_root: No library name was provided" >&2; return 1; }
  local lib_name="${1}"
  local root_dir
  root_dir="$(tst.get_repo_root)" \
    || { echo "tst.source_lib_from_root: Unable to get root directory of current repo" >/dev/tty; return 1; } 
  PATH="${root_dir}:${PATH}" source "$lib_name" \
    || { echo "tst.source_lib_from_root: Unable to source library '$lib_name'" >/dev/tty; return 1; }
}
