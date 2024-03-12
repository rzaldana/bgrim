#!/usr/bin/env bash

set -euo pipefail

# Source library
. ../../bgrim.bash

# file to store name of temporary file
tempfile_name_file="$(mktemp)"

trap "rm -f '$tempfile_name_file'" EXIT

# Create tmpfile
(
declare tmpfile
bg.tmpfile "tmpfile"

# Write name of tempfile to tempfile_name_file
echo "$tmpfile" >"$tempfile_name_file"

# Check that file exists
stat "$tmpfile" 1>/dev/null 2>&1 \
  || { echo "file '$tmpfile' does not exist" >&2; exit 1; }
)

# Check that file is gone after exiting subshell
if stat "$(< "$tempfile_name_file")" 1>/dev/null 2>&1; then
  exit 1
fi


