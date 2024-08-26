#!/usr/bin/env bash

# Get directory of current script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source library
source "${script_dir}/../../../bgrim.bash"

func1() {
  bg.get_parent_routine_name
}

func1

