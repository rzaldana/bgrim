#!/usr/bin/env bash

# Get directory of current script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source library
source "${script_dir}/../../../bgrim.bash"

bg.get_parent_routine_name
