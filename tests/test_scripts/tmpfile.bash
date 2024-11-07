#!/usr/bin/env bash

set -euo pipefail

# Get the directory of the script that's currently running
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source test library
# shellcheck source=./lib/tst.bash
PATH="$SCRIPT_DIR/../lib:$PATH" source tst.bash

# Source library to be tested
tst.source_lib_from_root "cli.bash"

# file to store name of temporary file
tempfile_name_file1="$(mktemp)"
tempfile_name_file2="$(mktemp)"

#trap "rm -f '$tempfile_name_file1' '$tempfile_name_file2'" EXIT

# Create tmpfiles
(
declare tmpfile1
declare tmpfile2

bg.tmpfile.new "tmpfile1"
bg.tmpfile.new "tmpfile2"

# Write name of tempfile to tempfile_name_file
echo "$tmpfile1" >"$tempfile_name_file1"
echo "$tmpfile2" >"$tempfile_name_file2"

# Check that file exists
stat "$tmpfile1" 1>/dev/null 2>&1 \
  || { echo "file '$tmpfile1' does not exist" >&2; exit 1; }

stat "$tmpfile2" 1>/dev/null 2>&1 \
  || { echo "file '$tmpfile2' does not exist" >&2; exit 1; }
)

# Check that file is gone after exiting subshell
if stat "$(< "$tempfile_name_file1")" 1>/dev/null 2>&1; then
  echo "file '$(< "$tempfile_name_file1")' still exists" >&2
  exit 1
fi

if stat "$(< "$tempfile_name_file2")" 1>/dev/null 2>&1; then
  exit 2 
fi
