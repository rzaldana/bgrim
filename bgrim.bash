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

bg::is_valid_var_name() {
  local input_string="${1:-}"
  local re="^[a-zA-Z0-9_]+$"
  if [[ "$input_string" =~ $re ]]; then
    return 0
  else
    return 1
  fi
}

bg::is_array() {
  local array_name="${1:-}"  
  local re="declare -a"
  local array_attributes
  array_attributes="$(declare -p "$array_name" 2>/dev/null)" \
    || return 1

  if [[ "$array_attributes" =~ $re ]]; then
    return 0
  else
    return 1
  fi
}

bg::in_array() {
  local value="${1:-}"
  local array_name="${2:-}"

  # Check if array exists
  if ! bg::is_array "$array_name"; then
    echo "The array with name '$array_name' does not exist" >&2
    return 2
  fi

  # Store values of array into a temporary local array
  local -a tmp_array
  eval "tmp_array=( \"\${${array_name}[@]}\")"

  for elem in "${tmp_array[@]}" ; do
    [[ "$elem" == "$value" ]] && return 0
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
