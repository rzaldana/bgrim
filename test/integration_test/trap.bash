#!/usr/bin/env bash

# Source library
. ../../bgrim.bash

# Create temporary file
tmpfile="$(mktemp)"

trap "rm -f '$tmpfile'" 'EXIT'

(
  bg.trap "echo 'heey' >'$tmpfile'" EXIT
  bg.trap "echo 'wohoo'>>'$tmpfile'" EXIT
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

