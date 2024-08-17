#!/usr/bin/env bash

# Source library
. ../../bgrim.bash

set -o pipefail

# shellcheck disable=SC2120
main() {
  shopt -s lastpipe
  bg.cli.init \
   | bg.cli.add_opt "f" "flag" "myflag" "help message" \
   | bg.cli.parse "$@"
}

main 
