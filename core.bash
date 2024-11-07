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
# CONSTANTS
################################################################################
export __BG_MKTEMP="mktemp"

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
bg.var.is_array() ( 
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
)

# description: |
#   This function is meant to ensure that a function receives all the arguments
#   it expects. It expects an array called 'required_args' to be set in its
#   environment and it takes all the arguments that a function receives as its
#   cli arguments. It checks if there is a cli argument for every entry in the 
#   'required_args' array and assigns the value of the cli argument to a variable
#   with the name of the required arg
# inputs:
#   stdin:
#   args:
#     rest: cli arguments to validate
#   environment:
#     required_args: an array with an entry for every required arg
# outputs:
#   stdout:
#   stderr: |
#     an error message if the required_args array is not set or is empty
#     an error message if a required_arg is not provided in the cli arguments
#   return_code:
#     0: "if all expected positional arguments are received"
#     1: "if an expected positional argument is not provided"
#     2: "the 'required_args' array is empty or not set"
# tags:
#   - "core_utils"
# examples:
#   - script: |
#
#       #!/usr/bin/env bash
#
#       source core.bash
#
#       set +e # do not exit on error
#
#       myfunc() {
#         local arg1 arg2
#         required_args=( arg1 arg2 )
#         if ! core.require_args "$@" ; then
#           return 2
#         fi
#
#         echo "arg1=$arg1"
#         echo "arg2=$arg2"
#       }
#       
#       echo "Function invocation with all required arguments:"
#       echo "================================================"
#       myfunc "value1" "value2"
#       ret_code="$?"
#       echo "return code: $ret_code"
#       echo "Function invocation with required argument missing:"
#       echo "================================================"
#       myfunc "value1" 
#       ret_code="$?"
#       echo "return code: $ret_code"
#     output: |
#       Function invocation with all required arguments:
#       ================================================
#       arg1=value1
#       arg2=value2
#       return code: 0
#       Function invocation with required argument missing:
#       ================================================
#       ERROR: myfunc: argument 2 (arg2) is required but was not provided
#       return code: 2
core.require_args() {

  local calling_function
  calling_function="${FUNCNAME[1]}"

  # Fail if required_args array is not set 
  if ! bg.var.is_array 'required_args'; then
    echo "ERROR: require_args: 'required_args' array not found" >&2
    return 2
  fi

  # Fail if required_args array has length 0
  if [[ "${#required_args[@]}" == "0" ]]; then
    echo "ERROR: require_args: 'required_args' array is empty" >&2
    return 2
  fi

  local -a provided_args=( "$@" )

  # Validate that required args are all valid variable names
  local valid_var_name_re="^[a-zA-Z_][a-zA-Z0-9_]+$"
  for arg in "${required_args[@]}"; do
    # Remove type prefix, if present
    arg="${arg##*:}"
    if ! [[ "$arg" =~ $valid_var_name_re ]]; then
      echo "ERROR: $calling_function: '$arg' is not a valid variable name" >&2
      return 1
    fi
  done

  # Check that there is a cli argument for every required arg
  if [[ "${#provided_args[@]}" -lt "${#required_args[@]}" ]]; then
    printf "ERROR: $calling_function: argument %s (%s) is required but was not provided\n" \
      "$(( ${#provided_args[@]} + 1 ))" \
      "${required_args[${#provided_args[@]}]}" \
      >&2
    return 1
  else
    # assign the value of each cli argument to the corresponding required arg
    local type_prefix
    local provided_arg
    local required_arg
    for ((i=0; i < "${#required_args[@]}" ; i++)); do
      required_arg="${required_args[$i]}"
      provided_arg="${provided_args[$i]}"

      # For each required arg, if it has a type prefix,
      # check that the provided type is of a type that 
      # matches the type prefix
      local re=".+:.+"
      if [[ "$required_arg" =~ $re ]]; then 
        IFS=: read -r type_prefix required_arg <<<"$required_arg"
        #type_prefix="${required_arg%%:*}"
        #required_arg="${required_arg##*:}"

        case "${type_prefix}" in
          "ra")
            if ! bg.var.is_array "$provided_arg"; then
              echo "ERROR: $calling_function: array variable with name '$provided_arg' does not exist" >&2
              return 1 
            fi

            if ! bg.var.is_set "$provided_arg"; then
              echo "ERROR: $calling_function: array variable with name '$provided_arg' is not set" >&2
              return 1
            fi
            ;;

          "rwa")
            if ! bg.var.is_array "$provided_arg"; then
              echo "ERROR: $calling_function: array variable with name '$provided_arg' does not exist" >&2
              return 1 
            fi

            if ! bg.var.is_set "$provided_arg"; then
              echo "ERROR: $calling_function: array variable with name '$provided_arg' is not set" >&2
              return 1
            fi

            if bg.var.is_readonly "$provided_arg"; then
              echo "ERROR: $calling_function: array variable with name '$provided_arg' is read-only" >&2
              return 1
            fi
            ;;
          *)
            echo "ERROR: $calling_function: Type prefix '${type_prefix}' for variable '$required_arg' is not valid. Valid prefixes are: 'ra' and 'rwa'" >&2
            return 1
            ;;
        esac
      fi

      # TODO: sanitize arguments in provided_args by replacing all double quotes(")
      # in the arg with escaped double quotes to avoid arbitrary code execution
      eval "${required_arg}=\"\${provided_arg}\""
    done
  fi

}


################################################################################
# Checks if the given string is a valid variable name (i.e. it's made up 
# exclusively of alphanumeric characters and underscores and it does not start
# with a number
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
bg.str.is_valid_var_name() ( 
  local var_name
  local -a required_args=( "var_name" )
  if ! core.require_args "$@"; then
    return 2
  fi

  local re="^[a-zA-Z_][a-zA-Z0-9_]*$"
  if [[ "$var_name" =~ $re ]]; then
    return 0
  else
    return 1
  fi
)

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
bg.env.clear_shell_opts() {
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
bg.trap.clear_all() {
  # Clear pseudo-signal traps
  trap - RETURN
  trap - DEBUG
  trap - EXIT
  trap - ERR
  #echo "cleared all pseudo-signal traps" >/dev/tty

  # read all signal names available in the system
  # into an array 
  local -a signals_array
  local IFS
  IFS=' '$'\t'
  while IFS= read -r line; do
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
bg.env.clear_vars_with_prefix() {
  local -a required_args=( 'prefix' )
  local prefix
  if ! core.require_args "$@"; then
    return 2
  fi

  # Check that prefix is not empty
  [[ -z "$prefix" ]] \
    && printf '%s\n' "ERROR: arg1 (prefix) is empty but is required" >&2 \
    && return 1

  # Check that prefix is a valid variable name
  if ! bg.str.is_valid_var_name "$prefix"; then \
    printf '%s\n' "ERROR: '$prefix' is not a valid variable prefix" >&2
    return 1
  fi

  eval 'local -a vars_with_prefix=( ${!'"$prefix"'@} )'
  # shellcheck disable=SC2156
  for var in "${vars_with_prefix[@]}"; do
    unset "$var"
  done
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
#core.is_shell_bash() {
#  local bash_version_var_name="${_BG_BASH_VERSION_VAR_NAME:-BASH_VERSION}"
#  if core.is_empty "${!bash_version_var_name}"; then
#    return 1
#  else
#    return 0
#  fi
#}



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
bg.arr.is_member() ( 
  local value
  local array_name
  local -a required_args=( 'ra:array_name' 'value' )
  if ! core.require_args "$@"; then
    return 2
  fi

  # Check if array exists
  if ! bg.var.is_array "$array_name"; then
    echo "The array with name '$array_name' does not exist" >&2
    return 2
  fi

  # Store values of array into a temporary local array
  #local -a tmp_array
  #eval "tmp_array=( \"\${${array_name}[@]}\")"

  array_name="${array_name}[@]"
  for elem in "${!array_name}" ; do
    [[ "$elem" == "$value" ]] && return 0
  done
  return 1
)

################################################################################
# Description: Checks if a function with the given name exists
# Globals:
#   None
# inputs:
#   stdin:
#   args:
#     1: "function_name"
# outputs:
#   stdout:
#   stderr: error message if no args are provided
#   return_code:
#     0: "if arg1 is a string of length 0 or is not provided"
#     1: "if arg1 is a string of length more than 1"
# tags:
#   - "syntax_sugar"
# Returns:
#   0: if the given value refers to a function in the environment 
#   1: if no function with the given name exists in the environment 
#   2: if no arguments are provided 
################################################################################
bg.func.is_declared() ( 
  local function_name
  local -a required_args=( 'function_name' )
  if ! core.require_args "$@"; then
    return 2
  fi

  if declare -f "$function_name" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
)

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
bg.str.is_valid_command() ( 
  local command_name
  local -a required_args=( 'command_name' )
  if ! core.require_args "$@"; then
    return 2
  fi

  local command_type
  command_type="$(type -t "$command_name" 2>/dev/null)"
  local ret_code="$?"

  [[ "$ret_code" != 0 ]] && return 1 
  [[ "$command_type" = "keyword" ]] && return 1
  return 0
)

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
bg.str.is_valid_shell_opt() ( 
  local opt_name
  local opt_name_iterator
  local opt_value

  local -a required_args=( 'opt_name' )
  if ! core.require_args "$@"; then
    return 2
  fi

  opt_name="${1:-}"

  # shellcheck disable=SC2034
  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    [[ "$opt_name" == "$opt_name_iterator" ]] \
      && return 0
  done < <(set -o 2>/dev/null)
  return 1
)

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
bg.str.is_valid_bash_opt() ( 
  local opt_name
  local opt_name_iterator
  local opt_value
  local -a required_args=( 'opt_name' )
  if ! core.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2034
  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    [[ "$opt_name" == "$opt_name_iterator" ]] \
      && return 0
  done < <(shopt 2>/dev/null)
  return 1
)

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
core.is_shell_opt_set() ( 
  local opt_name
  local opt_name_iterator
  local opt_value
  local is_valid_opt=""

  local -a required_args=( 'opt_name' )
  if ! core.require_args "$@"; then
    return 2
  fi

  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    if [[ "$opt_name" == "$opt_name_iterator" ]]; then
      is_valid_opt="true"
      if [[ "$opt_value" == "on" ]]; then
        return 0
      fi
    fi
  done < <(set -o 2>/dev/null)

  # Print error message to stdout if given option is not valid
  [[ -z "$is_valid_opt" ]] \
    && echo "'$opt_name' is not a valid shell option" >&2 \
    && return 2
  return 1
)

# description: |
#   Returns the command that has been specified to run when the given signal is caught
#   Returns nothing if the given signal does not have a trap set
# inputs:
#   stdin:
#   args:
#     1: signal spec
# outputs:
#   stdout: command that has been specified to run when the signal spec is caught
#   stderr:
#   return_code:
#     0: "if the trap command was successfully retrieved"
#     1: "if there was an error while retrieving the trap command"
# dependencies:
# tags:
#   - "error_handling" 
bg.trap.get() ( 
  local signal_spec
  local -a required_args=( 'signal_spec' )
  if ! core.require_args "$@"; then
    return 2
  fi

  local trap_list_output
  trap_list_output="$( trap -p "$signal_spec" 2>&1 )" \
    || { 
      printf "Error retrieving trap for signal '%s'. " "$signal_spec" >&2
      printf "Error message: '%s'" "$trap_list_output" >&2
      return 1
    }

  # Remove leading 'trap --' string
  trap_list_output="${trap_list_output#'trap -- '}"

  # Remove trailing signal spec
  trap_list_output="${trap_list_output%" $signal_spec"}"

  # Remove outer single quotes, if any
  trap_list_output="${trap_list_output#\'}"
  trap_list_output="${trap_list_output%\'}"

  # Remove escape sequences
  trap_list_output="${trap_list_output//\'\\\'/}"


  echo "$trap_list_output"
)

# description: |
#   If the signal provided does not have a signal set or the signal is ignored,
#   this function will set the given command as the signal trap. If the signal 
#   already has a trap set, the function will add a newline after the previous
#   signal trap command and append the given command to the existing trap 
#   command
# inputs:
#   stdin:
#   args:
#     1: trap command
#     2: signal spec
# outputs:
#   stderr:
#   return_code:
#     0: "if the trap was successfully set"
#     1: "if there was an error while setting the trap command"
# dependencies:
# tags:
#   - "error_handling" 
bg.trap.add() {

  local trap_command
  local signal_spec
  local -a required_args=( 'trap_command' 'signal_spec' )
  if ! core.require_args "$@"; then
    return 2
  fi

  signal_spec="${2:-}"

  # Get previous trap command, if any
  previous_trap_cmd="$(bg.trap.get "$signal_spec" 2>/dev/null)" \
    || { printf "Error retrieving existing trap for signal '%s'" "$signal_spec"
         return 1
        } >&2

  if [[ -n "$previous_trap_cmd" ]]; then
    trap_command="$(printf "%s\n%s" "$previous_trap_cmd" "$trap_command")"
  fi
 
  trap "$trap_command" "$signal_spec" 2>/dev/null \
    || { printf "Error setting new trap for signal '%s'" "$signal_spec"
         return 1
       } >&2
}

# description: |
#   Creates a temporary file using 'mktemp' and sets an EXIT trap for
#   the file to be deleted upon exit of the current shell process. It
#   takes the name of a variable as it's only argument and places the
#   path to the temporary file in the variable whose name is provided.
# inputs:
#   stdin:
#   args:
#     1: filename variable
# outputs:
#   stderr:
#   return_code:
#     0: "if the file was successfully created and the exit trap set"
#     1: "if there was an error while creating the file or setting the trap"
# dependencies:
# tags:
#   - "error_handling" 
bg.tmpfile.new() {
  local filename_var
  local -a required_args=( 'filename_var' )
  if ! core.require_args "$@"; then
    return 2
  fi

  # Validate that filename_var is a valid variable name
  if ! bg.str.is_valid_var_name "$filename_var"; then
    echo "ERROR: '$filename_var' is not a valid variable name" >&2
    return 1
  fi

  local tmpfile_name
  tmpfile_name="$("$__BG_MKTEMP")" \
    || { echo "ERROR: Unable to create temporary file" >&2; return 1; }
  bg.trap.add "rm -f '$tmpfile_name'" 'EXIT' \
    || { echo "ERROR: Unable to set exit trap to delete file '$tmpfile_name'" >&2; return 1; }

  # Assign name of tmpfile to variable whose name is contained in
  # filename_var
  eval "$filename_var=$tmpfile_name"
}



# description: |
#   returns 0 if the given string is a readonly variable
#   returns 1 if the variable is not readonly or is unset
# inputs:
#   stdin:
#   args:
#     1: "variable name"
# outputs:
#   stdout:
#   stderr: error message when string was not provided
#   return_code:
#     0: "when the variable is readonly"
#     1: "when the variable is not readonly or unset"
# tags:
#   - "cli parsing"
bg.var.is_readonly() ( 
  local var_name
  local -a required_args=( 'var_name' )
  if ! core.require_args "$@"; then
    return 2
  fi

  local re="^declare -[a-z]*r[a-z]* "
  local var_attributes
  var_attributes="$(declare -p "$var_name" 2>/dev/null)" \
    || return 1

  if [[ "$var_attributes" =~ $re ]]; then
    return 0
  else
    return 1
  fi
)


# description: |
#   returns 0 if the given variable name refers to a declared variable 
#   returns 1 if the given variable name is not declared in the execution context 
# inputs:
#   stdin:
#   args:
#     1: "variable name"
# outputs:
#   stdout:
#   stderr: error message when string was not provided
#   return_code:
#     0: "when the variable is set"
#     1: "when the variable is not set 
# tags:
# - "utility"
bg.var.is_declared() ( 
  local var_name
  local -a required_args=( "var_name" )
  if ! core.require_args "$@"; then
    return 2 
  fi
  declare -p "$var_name" 1>/dev/null 2>&1
)

# description: |
#   returns 0 if the given variable name refers to a variable that's declared and
#   has a set value (even if it's an empty string or empty array). returns 1 if 
#   the given variable name is not declared or is declared but does not have a
#   set value.
# inputs:
#   stdin:
#   args:
#     1: "variable name"
# outputs:
#   stdout:
#   stderr: error message when string was not provided
#   return_code:
#     0: "when the variable is set"
#     1: "when the variable is not set 
# tags:
# - "utility"
bg.var.is_set() ( 
  local var_name
  local -a required_args=( "var_name" )
  if ! core.require_args "$@"; then
    return 2 
  fi

  if ! bg.var.is_declared "$var_name"; then
    return 1
  fi

  regex='^declare -[a-zA-Z-]+ [a-zA-Z_][a-zA-Z0-9_]*\=.+$'
  if ! [[ "$( declare -p "$var_name" )" =~ $regex ]]; then
    return 1 
  fi
)

# description: |
#   reads lines from stdin and stores each line as an element
#   of the array whose name is provided in the first arg.
#   Lines are assumed to be separated by newlines
# inputs:
#   stdin: elements to store in array
#   args:
#     1: "array name"
# outputs:
#   stdout:
#   stderr: |
#     error message when array name is missing or array is readonly 
#   return_code:
#     0: "when lines were successfully stored in array"
#     1: "when an error ocurred"
# tags:
#   - "cli parsing"
bg.arr.from_stdin() {
  local array_name
  local -a required_args=( 'rwa:array_name' )
  if ! core.require_args "$@"; then
    return 2
  fi

  # Validate args
  if ! bg.str.is_valid_var_name "$array_name"; then
    echo "ERROR: '$array_name' is not a valid variable name" >&2
    return 1
  fi

  if bg.var.is_readonly "$array_name"; then
    echo "ERROR: '$array_name' is a readonly variable" >&2
    return 1
  fi

  # Empty array
  eval "${array_name}=()"

  # Read lines from stdin
  while IFS= read -r line; do
    eval "${array_name}+=( \"\${line}\")"
  done
}


# description: |
#   Returns the name of the parent routine of the
#   currently executing function, where the currently
#   executing function is the function that called
#   core.get_parent_routine_name
# inputs:
#   stdin: null 
#   args: null
# outputs:
#   stdout: null
#   stderr: null
#   return_code:
#     0: "always" 
# tags:
#   - "std"
core.get_parent_routine_name() {
  # If calling function is running at top-level
  # or if calling routine is the top-level 'main'
  # routine, return the name of the script
  if [[ "${#FUNCNAME[@]}" -le 3 ]]; then
    printf "%s" "$( basename "${BASH_SOURCE[1]}" )"
  else
    printf "%s" "${FUNCNAME[2]}"
  fi
}

# description: |
#   Takes a string and the name of an array and prints 
#   the index of the string in the array, if the string
#   is an item an array. If the string is not a member
#   of the array or if the provided array name does not
#   refer to an existing array in the function's execution
#   environment, it returns 1 and prints an error message
#   to stderr
# inputs:
#   stdin: null 
#   args:
#     1: "item"
#     2: "array_name"
# outputs:
#   stdout: index of the provded item in the array
#   stderr: |
#     error message if validation of arguments fails,
#     if the given item is not a member of the array
#     or if the array does not exist 
#   return_code:
#     0: "when the item was found in the array"
#     1: "when an error ocurred"
# tags:
#   - "arrays"
bg.arr.index_of() {
  local array_name
  local item

  # Check number of arguments
  local -a required_args=( "ra:array_name" "item" )
  if ! core.require_args "$@"; then
    return 2 
  fi

  # Check if array exists
  # shellcheck disable=SC2031
  if ! bg.var.is_array "${array_name}"; then
    # shellcheck disable=SC2031
    printf \
      "ERROR: array '%s' not found in execution environment" \
      "${array_name}" \
      >&2
    return 1
  fi


  local -i array_length
  # shellcheck disable=SC2031
  eval "array_length=\"\${#${array_name}[@]}\""

  local current_item
  local -i index="-1"
  for ((index=0; index<array_length; index++)); do
    # shellcheck disable=SC2031
    eval "current_item=\${${array_name}[$index]}" 
    if [[ "$current_item" == "$item" ]]; then
      printf "%s" "$index"
      return 0
    fi
  done

  # shellcheck disable=SC2031
  printf \
    "ERROR: item '%s' not found in array with name '%s'" \
    "$item" \
    "$array_name" \
    >&2
  return 1
}

