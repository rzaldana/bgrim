#!/usr/bin/env bash
################################################################################

################################################################################
# Checks if the variable with the given name is empty 
# Globals:
#   None
# Arguments:
#   Name of variable to check
# Outputs:
#   None
# Returns:
#   0 if the variable with the given name is unset or expands to an empty string
#   1 otherwise
################################################################################
bg::is_empty() {
  local var_name="${1:-}"
  [[ -z "${!var_name}" ]] \
    && return 0
  return 1 
}

################################################################################
# Checks if currently running shell is bash 
# Globals:
#   _BG_BASH_VERSION_VAR_NAME: (test only) if set, makes the function check the 
#     value of the variable whose name is specified in this variable
# Arguments:
#   None
# Outputs:
#   None
# Returns:
#   0 if the BASH_VERSION is set
#   1 if the BASH_VERSION is unset
################################################################################
bg::is_shell_bash() {
  local bash_version_var_name="${_BG_BASH_VERSION_VAR_NAME:-BASH_VERSION}"
  if bg::is_empty "${bash_version_var_name}"; then
    return 1
  else
    return 0
  fi
}
