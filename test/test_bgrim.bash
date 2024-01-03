#!/usr/bin/env bash

################################################################################

setup_suite() {
  LIBRARY_NAME="bgrim.bash"

  # Get the absolute path of the library under test
  LIBRARY_PATH="$(cd ..>/dev/null && pwd)/$LIBRARY_NAME"

  # source library
  # shellcheck src=../bgrim.bash
  source "$LIBRARY_PATH"
}

test_is_empty_returns_0_if_given_no_args() {
  assert \
    'bg::is_empty' \
    "bg::is_empty should return 0 when the given var name is unset"
}

test_is_empty_returns_0_if_given_an_empty_string() {
  assert \
    'bg::is_empty ""' \
    "bg::is_empty should return 0 when the given var name is unset"
}

test_is_empty_returns_1_if_given_a_non_empty_string() {
  TEST_VAR="test_string"
  assert_fail \
    'bg::is_empty test_string' \
    "bg::is_empty should return 0 when the given var name is unset"
}

test_is_shell_bash_returns_0_if_running_in_bash() {
  export FAKE_BASH_VERSION="x.x.x"
  export _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
  assert \
    'bg::is_shell_bash' \
    "bg:is_shell_bash should return 0 when BASH_VERSION variable is set"
}

test_is_shell_bash_returns_1_if_not_running_in_bash() {
  export FAKE_BASH_VERSION
  export _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
  assert_fail \
    bg::is_shell_bash \
    "bg:is_shell_bash returns 1 when BASH_VERSION variable is unset"
}

test_in_array_returns_0_when_the_first_arg_matches_any_of_the_latter_args() {
  local -a test_array=( "val1" "val2" "val3" ) 

  assert \
    'bg::in_array "val2" "${test_array[@]}"' \
    "in_array should return 0 when first arg matches any of the latter args"
}

test_in_array_returns_1_when_the_first_arg_is_not_found_in_any_latter_arg() {
  local -a test_array=( "val1" "val2" "val3" ) 
  assert_fail \
    'bg:in_array "val4" "${test_array[@]"' \
    "in_array should return 1 when 1st arg doesn't match any latter args"
}

test_clear_options_clears_all_options_in_the_environment() {
  # Set a few specific options
  set -o pipefail
  set -o vi
  shopt -s extglob

  # Run function 
  bg::clear_options

  # All shell options are unset
  assert_equals "" "$-" '$- should expand to an empty string but it doesn'\''t'

  # All bash-specific options are unset
  assert_equals "" "$(shopt -s)" 'There should be no set bash-specific options'
}
