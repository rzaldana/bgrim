#!/usr/bin/env bash

# Copyright (c) 2024 Raul Armando Zaldana Calles

################################################################################
##############       ######      ###       #####  ###         ##################
#############         ####       ##         ###   ##           #################
#############   ###    ##    ######   ###    ##   ##   #   #   #################
#############   ####   ##   #######   ####   ##   ##   #####   #################
#############   #      ##   #######   ####   ##   ##   #####   #################
#############   ##    ###   #######   ###    ##   ##   #####   #################
#############   ####   ##   #######         ###   ##   #####   #################
#############   ####   ##   #    ##         ###   ##   #####   #################
#############   ####   ##   #    ##   ###    ##   ##   #####   #################
#############   ####   ##   ###  ##   ####   ##   ##   #####   #################
#############   #     ####       ##   ####   ##   ##   #####   #################
#############   ##   ######      ##   ####   ##   ##   #####   #################
#############  ####################  ##########  ###########  ##################
############# ##################### ########### ############ ###################
################################################################################

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


################################################################################
# Description: Checks if the first argument is an empty string 
# Globals: null
# Arguments:
#   1: string to check
# Outputs: null
# Returns:
#   0: if the first argument is missing or an empty string 
#   1: otherwise
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

################################################################################
# Checks if the given string is a valid variable name (i.e. it's made up 
# exclusively of alphanumeric characters and underscores
# Globals:
#   None
# Arguments:
#   String to evaluate
# Outputs:
#   None
# Returns:
#   0 if the given string is a valid variable name 
#   1 otherwise
################################################################################
bg::is_valid_var_name() {
  local input_string="${1:-}"
  local re="^[a-zA-Z0-9_]+$"
  if [[ "$input_string" =~ $re ]]; then
    return 0
  else
    return 1
  fi
}

################################################################################
# Checks if an array with the given name exists in the current environment
# i.e. if a variable with the given name and the -a attribute exists
# Globals:
#   None
# Arguments:
#   Name of array to look for
# Outputs:
#   None
# Returns:
#   0 if the given name refers to an existing array variable
#   1 otherwise
################################################################################
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

################################################################################
# Checks if the given value exists in the array with the given name 
# Globals:
#   None
# Arguments:
#   Value to look for
#   Name of array to look through
# Outputs:
#   Writes error message to stderr if return code is not 0 or 1 
# Returns:
#   0 if the given value exists in the array with the given name
#   1 if the given value does not exist in the array with the given name
#   2 if there is no array in the environment with the given name
################################################################################
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


################################################################################
# Description: Checks if the given value exists in the array with the given name 
# Globals:
#   None
# Arguments:
#   - Value to look for
#   - Name of array to look through
# Outputs:
#   - Writes error message to stderr if return code is not 0 or 1 
# Returns:
#   0: if the given value exists in the array with the given name
#   1: if the given value does not exist in the array with the given name
#   2: if there is no array in the environment with the given name
################################################################################
bg::is_function() {
  local fn_name="${1:-}"

  if declare -f "$fn_name" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}


################################################################################
# Description: |
#   Runs the function with the given name once per line in the stdin.
#   The passed in name must refer to a function in the environment and the
#   referenced function must take its input from stdin. If any of the 
#   passed in function's execution fails, the return code of the failed
#   function will be returned in an error message. 
# Globals: null
# Arguments:
#   1: name of function to execute
# Outputs:
#   - Writes error message to stderr if return code is not 0 or 1 
# Returns:
#   0: all function executions of the given function were successful
#   1: an error occurred
################################################################################
bg::map() {
  local fn_name="${1:-}"

  # Check if first arg is set
  [[ -n "$fn_name" ]] \
    || { echo "${FUNCNAME[0]}: no args were provided" >&2
         return 1
       }

  # Check if first arg is a function
  bg::is_function "$fn_name" \
    || { echo "${FUNCNAME[0]}: function with name '$fn_name' not \
found in the environment" >&2
          return 1
       }
  local line
  local ret_code

  while IFS= read -r line; do
    "${fn_name}" <<<"$line"
    ret_code="$?" 
    [[ "$ret_code" == "0" ]] \
      || { echo \
            "${FUNCNAME[0]}:\
 execution of function '$fn_name' failed with status code\
 '${ret_code}' for input '$line'" >&2
            return 1
          }
  done
}

################################################################################
# Clears all options in the environment that can be set with both the 'set' and
# the 'shopt' built-in commands 
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes all the options that were set in the environment before clearing
#     in a format that can be read by bg::restore_options (not yet implemented)
# Returns:
#   0 in all cases
################################################################################
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
