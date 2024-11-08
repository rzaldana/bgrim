#!/usr/bin/env bash

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/../lib:$PATH" source tst.bash

# Source library to be tested
tst.source_lib_from_root "bgrim.bash"

# Create temporary file
tmpfile="$(mktemp)"

trap "rm -f '$tmpfile'" 'EXIT'

(
  bg.trap.add "echo 'heey' >'$tmpfile'" EXIT
  bg.trap.add "echo 'wohoo'>>'$tmpfile'" EXIT
)

# Check contents of tmpfile
# line 1
if ! [[ "$(awk 'NR==1 {print; exit}' "$tmpfile")" == "heey" ]]; then
  echo "First trap didn't fire" >&2
  echo "Contents of '$tmpfile': $(< "$tmpfile")"
  exit 1
fi

# line 2
if ! [[ "$(awk 'NR==2 {print; exit}' "$tmpfile")" == "wohoo" ]]; then
  echo "Second trap didn't fire" >&2
  exit 1
fi

