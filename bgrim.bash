#!/usr/bin/env bash
################################################################################

################################################################################
# Checks if the first argument is an empty string 
# Globals:
#   None
# Arguments:
#   Sstring to check
# Outputs:
#   None
# Returns:
#   0 if the first argument is missing or an empty string 
#   1 otherwise
################################################################################
bg::is_empty() {
  [[ -z "${1:-}" ]] \
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
  if bg::is_empty "${!bash_version_var_name}"; then
    return 1
  else
    return 0
  fi
}

bg::in_array() {
  local elem
  for elem in "${@:2}"; do
    [[ "$elem" == "${1:-}" ]] && return 0
  done
  return 1
}

bg::clear_options() {
  # Clear all options set with the 'set' built-in
  while read -r option_name option_status; do
    set +o "${option_name}" >/dev/null 2>&1
  done < <( set -o )

  # Clear all options set with the 'shopt' built-in
  while read -r option_name option_status; do
    shopt -u "${option_name}" >/dev/null 2>&1
  done < <( shopt )
}
