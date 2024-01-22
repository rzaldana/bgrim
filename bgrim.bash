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
# EMPTY COMMENT TEMPLATE
################################################################################
# description:
# inputs:
#   stdin:
#   args:
# #   1: "first command-line argument"
# #   2: "second command-line argument"
# #   rest: arguments 4 and above are interpreted the same way 
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "description of when the function returns status code 0"
#     1: "description of when the function returns status code 1"
# tags:
#   - "syntax_sugar"
################################################################################


################################################################################
# description: |
#   Clears all options in the environment that can be set with both the 'set' 
#   and the 'shopt' built-in commands 
# inputs:
#   stdin:
#   args:
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "always"
# tags:
#   - "changes env"
################################################################################
bg::clear_shell_opts() {
  # Clear all options set with the 'set' built-in
  while read -r option_name option_status; do
    set +o "${option_name}" >/dev/null 2>&1
  done < <( set -o )

  # Clear all options set with the 'shopt' built-in
  while read -r option_name option_status; do
    shopt -u "${option_name}" >/dev/null 2>&1
  done < <( shopt )
}


################################################################################
# description: |
#   Clears all traps in the environment
# inputs:
#   stdin:
#   args:
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "always"
# tags:
#   - "changes env"
################################################################################
bg::clear_traps() {
  # Clear pseudo-signal traps
  trap - RETURN
  trap - DEBUG
  trap - EXIT
  trap - ERR

  # read all signal names available in the system
  # into an array 
  local -a signals_array
  local IFS
  IFS=' '$'\t'
  while IFS= read -r line; do
    shift 1
    # shellcheck disable=SC2086
    set -- $line
    for token in "${@}"; do
      [[ "$token" =~ [0-9]{1,3}\) ]] || signals_array+=("$token")
    done
  done < <(trap -lp)

  # iterate through the array of available signals
  # to clear all traps
  for sig in "${signals_array[@]}"; do
    trap - "$sig"
  done
}

################################################################################
# description: |
#   Clears all variables in the environment that start with the given prefix.
#   Will unset global shell variables, as well as local and environment 
#   variables. Will return an error if the provided prefix is not a valid
#   function name (i.e. it's empty or not composed entirely of alphanumeric
#   characters and underscores)
# inputs:
#   stdin:
#   args:
#     1: "prefix"
# outputs:
#   stdout:
#   stderr: "Error message if prefix is not valid"
#   return_code:
#     0: "All variables with the given prefix were unset from the environment"
#     1: "The provided prefix was invalid"
# tags:
#   - "changes env"
################################################################################
bg::clear_vars_with_prefix() {
  local prefix="${1:-}"

  # Check that prefix is not empty
  [[ -z "$prefix" ]] \
    && printf '%s\n' "ERROR: arg1 (prefix) is empty but is required" \
    && return 1

  # Check that prefix is a valid variable name
  if ! bg::is_valid_var_name "$prefix"; then \
    printf '%s\n' "ERROR: '$prefix' is not a valid variable prefix"
    return 1
  fi

  eval 'local -a vars_with_prefix=( ${!'"$prefix"'@} )'
  # shellcheck disable=SC2156
  for var in "${vars_with_prefix[@]}"; do
    unset "$var"
  done
}



################################################################################
# description: |
#   Checks if the first argument is a string with length 0
# inputs:
#   stdin:
#   args:
#     1: "string to evaluate"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "if arg1 is a string of length 0 or is not provided"
#     1: "if arg1 is a string of length more than 1"
# tags:
#   - "syntax_sugar"
###############################################################################
bg::is_empty() {
  [[ -z "${1:-}" ]] \
    && return 0
  return 1 
}

################################################################################
# description: Checks if the shell program running this process is bash 
# inputs:
#   stdin:
#   args:
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "if the BASH_VERSION variable is set
#     1: "if the BASH_VERSION variable is unset"
# tags:
#   - "compatibility"
################################################################################
#bg::is_shell_bash() {
#  local bash_version_var_name="${_BG_BASH_VERSION_VAR_NAME:-BASH_VERSION}"
#  if bg::is_empty "${!bash_version_var_name}"; then
#    return 1
#  else
#    return 0
#  fi
#}

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
  local re="^[a-zA-Z_][a-zA-Z0-9_]+$"
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
# description: |
#   returns 0 if the first argument refers to a function, shell built-in, or
#   an executable in the PATH. Returns 1 otherwise.
# inputs:
#   stdin:
#   args:
#    1: "first command-line argument"
#    rest: all other parameters are ignored 
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "if the first arg is a function, shell built-in or executable in PATH"
#     1: "otherwise"
# tags:
#   - "syntax_sugar"
################################################################################
bg::is_valid_command() {
  local command_name="${1:-}"

  local command_type
  command_type="$(type -t "$command_name" 2>/dev/null)"
  local ret_code="$?"

  [[ "$ret_code" != 0 ]] && return 1 
  [[ "$command_type" = "keyword" ]] && return 1
  return 0
}


################################################################################
# description: |
#   Runs the given command once per line in the stdin. The first argument must 
#   refer to a valid function, shell built-in, or executable in the path. The 
#   rest of the args to this function will be provided as arguments to the 
#   command specified in the first arg. The referenced command must take its 
#   input from stdin. If any of the executions of the passed in command fails, 
#   the return code of the failed function will be returned in an error message. 
# inputs:
#   stdin:
#   args:
#     1: command to execute
#     rest: arguments to be passed in to the command in arg1
# outputs:
#   stdout: the output of the given command for every line in stdin 
#   stderr: any error messages
#   return_code:
#     0: all executions of the passed in command were successful
#     1: an error occurred
################################################################################
bg::map() {
  local command_name="${1:-}"
  shift 1

  # Check if first arg is set
  [[ -n "$command_name" ]] \
    || { echo "${FUNCNAME[0]}: no args were provided" >&2
         return 1
       }

  # Check if first arg is a valid command
  bg::is_valid_command "$command_name" \
    || { echo "${FUNCNAME[0]}: '$command_name' is not \
a valid function, shell built-in, or executable in the PATH" >&2
          return 1
       }
  local line
  local ret_code

  # Create string of args enclosed in single quotes
  local error_formatted_args=" with args"
  for arg in "$@"; do
    error_formatted_args="${error_formatted_args} '$arg'"
  done

  while IFS= read -r line; do
    "${command_name}" "$@" <<<"$line"
    ret_code="$?" 
    [[ "$ret_code" == "0" ]] \
      || { echo \
            "${FUNCNAME[0]}:\
 execution of command '$command_name'${*:+$error_formatted_args} failed with status code\
 '${ret_code}' for input '$line'" >&2
            return 1
          }
  done
}

################################################################################
# description: |
#   Runs the given command once per line in the stdin. All lines for which the
#   command returns 0 will be forwarded to stdout. All other lines will be
#   filtered out of the output. The first argument must refer to a valid 
#   function, shell built-in, or executable in the PATH. The rest of the args to 
#   this function will be provided as arguments to the command specified in the 
#   first arg. The referenced command must take its input from stdin.
# inputs:
#   stdin:
#   args:
#     1: command to execute
#     rest: arguments to be passed in to the command in arg1
# outputs:
#   stdout: lines for which the command returns 0
#   stderr: any error messages
#   return_code:
#     0: filtering was successful 
#     1: an error occurred
################################################################################
bg::filter() {
  # Check if first arg is set
  [[ "$#" -gt 0 ]] \
    || { echo "${FUNCNAME[0]}: no args were provided" >&2
         return 1
       }

  # Store first arg in variable and shift the rest of the args
  local command_name="${1:-}"
  shift 1


  # Check if first arg is a valid command
  bg::is_valid_command "$command_name" \
    || { echo "${FUNCNAME[0]}: '$command_name' is not \
a valid function, shell built-in, or executable in the PATH" >&2
          return 1
       }

  # shellcheck disable=SC2317
  __bg::filter_func() {
    local ret_code
    local line
    local command_name
    command_name="${1:-}"
    shift 1
    IFS= read -r line
    "${command_name}" "$@" 2>/dev/null <<<"$line" \
       && { printf '%s\n' "$line"; return 0; }
    return 0
  }

  bg::map __bg::filter_func "$command_name" "$@"

  unset -f _filter_func
}

################################################################################
# description: |
#   returns 0 if the given string is a valid long option name, i.e.
#   if it matches the following POSIX ERE regex: [[:alnum:]-]+
# inputs:
#   stdin:
#   args:
#     1: "string to evaluate"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "when the string matches the regex"
#     1: "when the string does not match the regex"
# tags:
#   - "cli parsing"
################################################################################
#bg::is_valid_long_option() {
  # turn off case insensitive regex matching
#  shopt -u nocasematch
#  local string
#  string="${1:-}"
#  local regex
#  regex='[[:alnum:]+'
#  [[ "$string" =~ $regex ]]
#
#
#}

#################################################################################
# description: |
#   returns 0 if the given string is a valid option name that can be set with the
#   'set -o [option name]' command. This command ony works with long option names
# inputs:
#   stdin:
#   args:
#     1: "string to evaluate"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "when the string is a valid shell option in the current bash"
#     1: "when the string is not a valid shell option in the current bash"
# tags:
#   - "option decorators"
################################################################################
bg::is_valid_shell_opt() {
  local opt_name
  local opt_name_iterator
  local opt_value

  opt_name="${1:-}"

  # shellcheck disable=SC2034
  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    [[ "$opt_name" == "$opt_name_iterator" ]] \
      && return 0
  done < <(set -o 2>/dev/null)
  return 1
}

#################################################################################
# description: |
#   returns 0 if the given string is a valid option name that can be set with the
#   'shopt -s [option name]' command.
# inputs:
#   stdin:
#   args:
#     1: "string to evaluate"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "when the string is a valid bash option in the current bash"
#     1: "when the string is not a valid bash option in the current bash"
# tags:
#   - "option decorators"
################################################################################
bg::is_valid_bash_opt() {
  local opt_name
  local opt_name_iterator
  local opt_value

  opt_name="${1:-}"

  # shellcheck disable=SC2034
  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    [[ "$opt_name" == "$opt_name_iterator" ]] \
      && return 0
  done < <(shopt 2>/dev/null)
  return 1
}

#################################################################################
# description: |
#   returns 0 if the given string is the name of the a shell option that is 
#   currently turned on through the 'set -o [option name]' command. This command
#   only works with long option names.
# inputs:
#   stdin:
#   args:
#     1: "option to evaluate"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "when the string is a valid shell option in the current bash"
#     1: "when the string is not a valid shell option in the current bash"
# tags:
#   - "option decorators"
################################################################################
bg::is_shell_opt_set() {
  local opt_name
  local opt_name_iterator
  local opt_value
  local is_valid_opt=""

  opt_name="${1:-}"

  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    if [[ "$opt_name" == "$opt_name_iterator" ]]; then
      is_valid_opt="true"
      if [[ "$opt_value" == "on" ]]; then
        return 0
      fi
    fi
  done < <(set -o 2>/dev/null)

  # Print error message to stdout if given option is not valid
  [[ -z "$is_valid_opt" ]] && echo "'$opt_name' is not a valid shell option" >&2
  return 1
}




