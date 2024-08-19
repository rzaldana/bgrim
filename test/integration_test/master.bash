#!/usr/bin/env bash


setup_suite() {
  LIBRARY_NAME="bgrim.bash"

  # Get the absolute path of the library under test
  LIBRARY_PATH="$(cd ../..>/dev/null && pwd)/$LIBRARY_NAME"

  # source library
  # shellcheck source=../bgrim.bash
  source "$LIBRARY_PATH" \
    || { echo "Unable to source library at $LIBRARY_PATH"; exit 1; }

  # set unofficial strict mode
  # (all functions should work in strict mode)
  #set -euo pipefail
}


test_trap_can_set_two_traps() {
  ./trap.bash
}

test_tmpfile_creates_two_temporary_files() {
  ./tmpfile.bash
}


