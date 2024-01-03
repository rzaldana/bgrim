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

test_is_empty_returns_0_if_the_given_var_name_is_unset() {
  unset TEST_VAR
  assert 'bg::is_empty TEST_VAR' "bg::is_empty should return 0 when the given var name is unset"
}

test_is_empty_returns_0_if_the_given_var_name_expands_to_an_empty_string() {
  TEST_VAR=""
  assert 'bg::is_empty TEST_VAR' "bg::is_empty should return 0 when the given var name is unset"
}

test_is_empty_returns_1_if_the_given_var_name_expands_to_a_non_empty_string() {
  TEST_VAR="test_string"
  assert_fail 'bg::is_empty TEST_VAR' "bg::is_empty should return 0 when the given var name is unset"
}

test_is_shell_bash_returns_0_if_running_in_bash() {
  export FAKE_BASH_VERSION="x.x.x"
  export _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
  assert bg::is_shell_bash "bg:is_shell_bash should return 0 when BASH_VERSION variable is set"
}

test_is_shell_bash_returns_1_if_not_running_in_bash() {
  export FAKE_BASH_VERSION
  export _BG_BASH_VERSION_VAR_NAME="FAKE_BASH_VERSION"
  assert_fail bg::is_shell_bash "bg:is_shell_bash returns 1 when BASH_VERSION variable is unset"
}
