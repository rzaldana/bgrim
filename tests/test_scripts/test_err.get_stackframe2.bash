#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/../lib:$PATH" source tst.bash

# Source library to be tested
tst.source_lib_from_root "err.bash"


myfunc_inner() {
  local -a stackframe=()
  caller 0 && __bg.err.get_stackframe "0" stackframe
  echo "${stackframe[0]} ${stackframe[1]} ${stackframe[2]}" >&2
}

myfunc() {
  myfunc_inner 
}
