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

# Check that we're running bash 
# This part needs to be POSIX shell compliant
# shellcheck disable=SC2128
if [ -z "${BASH_VERSINFO}" ]; then
  echo "[$0][ERROR]: This script is only compatible with Bash and cannot be run in other shells"
  exit 1
fi

# Check that we're running a supported version of bash
readonly -a __bg_min_bash_version=( '4' '4' '23' )
for vers_index in "${!BASH_VERSINFO[@]}"; do
  subversion="${BASH_VERSINFO[$vers_index]}"
  if (( subversion < __bg_min_bash_version[vers_index] )); then
    printf "[$0][ERROR]: This script is only compatible with Bash versions higher than %s.%s.%s but it's being run in bash version ${BASH_VERSION}\n" \
      "${__bg_min_bash_version[0]}" \
      "${__bg_min_bash_version[1]}" \
      "${__bg_min_bash_version[2]}"
    exit 1
  else
    break
  fi
done

################################################################################
# GLOBAL CONSTANTS
################################################################################
__bg_version='0.1.5'

################################################################################
# ARRAY FUNCTIONS
################################################################################
if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
  source in.bash
  source str.bash
fi


# description: returns the length of the array with the given name
# inputs:
#   stdin:
#   args:
#    1: "name of array"
# outputs:
#   stdout: "length of array"
#   stderr: "error message, if any"
#   return_code:
#     0: "if length was retrieved with no problem"
#     1: "if there was a problem with the given args"
bg.arr.length() {
  # Verify input arguments
  local -a required_args=( 'ra:array_name' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  local -i array_length
  # shellcheck disable=SC2031
  eval "array_length=\"\${#${array_name}[@]}\""
  echo "$array_length"
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
bg.arr.is_member() ( 
  local value
  local array_name
  local -a required_args=( 'ra:array_name' 'value' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Store values of array into a temporary local array
  #local -a tmp_array
  #eval "tmp_array=( \"\${${array_name}[@]}\")"

  # shellcheck disable=SC2030,SC2031
  array_name="${array_name}[@]"
  for elem in "${!array_name}" ; do
    [[ "$elem" == "$value" ]] && return 0
  done
  return 1
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
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Empty array
  # shellcheck disable=SC2031
  eval "${array_name}=()"

  # Read lines from stdin
  # shellcheck disable=SC2034
  while IFS= read -r line; do
    # shellcheck disable=SC2031
    eval "${array_name}+=( \"\${line}\")"
  done
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
#     1: "array_name"
#     2: "item"
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
  if ! bg.in.require_args "$@"; then
    return 2 
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
  bg.err.print "item '$item' not found in array with name '$array_name'"
  return 1
}

# description: |
#   Takes the name of an array and prints the array's
#   elements to stdout as a list of quote-delimited,
#   comma-separated words with the last word separated
#   by the word "and". Useful for output messages
#   that print array items
# inputs:
#   stdin: null 
#   args:
#     1: "array_name"
# outputs:
#   stdout: itemized list of array items 
#   stderr: |
#     error message if validation of arguments fails
#     or if the array does not exist 
#   return_code:
#     0: "when the array was properly verbalized"
#     1: "when an error ocurred"
#     2: "when argument validation failed"
# tags:
#   - "arrays"
bg.arr.itemize() {
  local array_name

  # Check number of arguments
  local -a required_args=( "ra:array_name" )
  if ! bg.in.require_args "$@"; then
    return 2 
  fi

  local array_length
  array_length="$( bg.arr.length "$array_name" )"

  case "${array_length}" in
    0)
      ;;
    1)
      eval "echo \"'\${${array_name}[0]}'\""
      ;;
    2)
      eval "echo \"'\${${array_name}[0]}' and '\${${array_name}[1]}'\""
      ;;
    *)
      eval "\
        local i
        for (( i = 0; i < ${array_length}; i++ )); do
          if (( i + 1 == ${array_length} )); then
            printf \"and '%s'\" \"\${${array_name}[\$i]}\"
          else
            printf \"'%s', \" \"\${${array_name}[\$i]}\"
         fi
        done
      "
  esac
}

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
  source str.bash
  source var.bash
  source arr.bash
fi

################################################################################
# ENVIRONMENT CONSTANTS 
################################################################################
BG_ENV_STACKTRACE_OUT="&2"

################################################################################
# ENVIRONMENT FUNCTIONS
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
bg.env.clear_vars_with_prefix() {
  local -a required_args=( 'prefix' )
  local prefix
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Check that prefix is not empty
  [[ -z "$prefix" ]] \
    && bg.err.print "arg1 (prefix) is empty but is required" \
    && return 1

  # Check that prefix is a valid variable name
  if ! bg.str.is_valid_var_name "$prefix"; then \
    bg.err.print "'$prefix' is not a valid variable prefix"
    return 1
  fi

  eval 'local -a vars_with_prefix=( ${!'"$prefix"'@} )'
  # shellcheck disable=SC2156
  for var in "${vars_with_prefix[@]}"; do
    unset "$var"
  done
}

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
bg.env.is_shell_opt_set() ( 
  local opt_name
  local opt_name_iterator
  local opt_value
  local is_valid_opt=""

  local -a required_args=( 'opt_name' )
  if ! bg.in.require_args "$@"; then
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
    && bg.err.print "'$opt_name' is not a valid shell option" \
    && return 2
  return 1
)

# description: |
#   Returns the name of the parent routine of the
#   currently executing function, where the currently
#   executing function is the function that called
#   bg.env.get_parent_routine_name
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
bg.env.get_parent_routine_name() {
  # If calling function is running at top-level
  # or if calling routine is the top-level 'main'
  # routine, return the name of the script
  
  # Get the length of FUNCNAME
  local -i funcname_length
  funcname_length="${#FUNCNAME[@]}" 

  # If length is less than 3, i.e. when this
  # function is being called at the top level
  if [[ "$funcname_length" -le 3 ]]; then
    bg.env.get_parent_script_name
  else
    printf "%s" "${FUNCNAME[2]}"
  fi
}

# description: |
#   Returns the name of the script that's currently 
#   executing, even if the function is called from
#   a sourced library. Only the basename, not the
#   entire path, is returned
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
bg.env.get_parent_script_name() {
  # Get the length of FUNCNAME
  local -i funcname_length
  funcname_length="${#FUNCNAME[@]}" 

  local -i top_level_index
  top_level_index=$(( funcname_length - 1 ))
  printf "%s" "$( basename "${BASH_SOURCE[$top_level_index]}" )"
}

################################################################################
# ERROR HANDLING CONSTANTS 
################################################################################
__BG_ERR_OUT="&2"
__BG_ERR_FORMAT='ERROR: %s\n'

################################################################################
# ERROR HANDLING FUNCTIONS 
################################################################################
# description: Prints a formatted error message. It will print error messages to
#   stderr by default but a different file or fd (if preceded by &) can be 
#   specified using the __BG_ERROR_OUT environment variable. The format of the 
#   error message can be customized by using the __BG_ERROR_FORMAT environment 
#   variable. __BG_ERROR_FORMAT accepts any of the format specifications 
#   that the printf shell built-in would take where the first non-format 
#   argument to printf is the error message.
# inputs:
#   stdin:
#   args:
#    1: "error message"
#   env_vars:
#     - name: "__BG_ERROR_FORMAT"
#       description: "formatting to apply to error messages"
#       default: "ERROR: %s\n"
#     - name: "__BG_ERROR_OUT"
#       description: "file where error messages will be written to"
#       default: "stderr"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "always"
bg.err.print() ( 
  local err_out_without_fd_prefix="${__BG_ERR_OUT#&}"
  if [[ "${err_out_without_fd_prefix}" != "${__BG_ERR_OUT}" ]]; then
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >&"$err_out_without_fd_prefix" || :
  else
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >"$err_out_without_fd_prefix" || :
  fi
)


if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
  source var.bash
  source str.bash
fi

################################################################################
# INPUT FUNCTIONS
################################################################################

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
#         if ! bg.in.require_args "$@" ; then
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
#       ERROR: argument 2 (arg2) is required but was not provided
#       return code: 2
bg.in.require_args() {

  local calling_function
  calling_function="${FUNCNAME[1]}"

  # Fail if required_args array is not set 
  if ! bg.var.is_array 'required_args'; then
    bg.err.print "'required_args' array not found"
    return 2
  fi

  # Fail if required_args array is not set 
  if ! bg.var.is_set 'required_args'; then
    bg.err.print "'required_args' array is empty"
    return 2
  fi

  local -a provided_args=( "$@" )

  # Validate that required args are all valid variable names
  local valid_var_name_re="^[a-zA-Z_][a-zA-Z0-9_]+$"
  for arg in "${required_args[@]}"; do
    # Remove type prefix, if present
    arg="${arg##*:}"
    if ! [[ "$arg" =~ $valid_var_name_re ]]; then
      bg.err.print "'$arg' is not a valid variable name"
      return 1
    fi
  done

  # Check that there is a cli argument for every required arg
  if [[ "${#provided_args[@]}" -lt "${#required_args[@]}" ]]; then
    bg.err.print "argument $(( ${#provided_args[@]} + 1 )) (${required_args[${#provided_args[@]}]}) is required but was not provided"
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
              bg.err.print "array variable with name '$provided_arg' does not exist"
              return 1 
            fi

            if ! bg.var.is_set "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' is not set"
              return 1
            fi
            ;;

          "rwa")
            if ! bg.var.is_array "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' does not exist"
              return 1 
            fi

            if ! bg.var.is_set "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' is not set"
              return 1
            fi

            if bg.var.is_readonly "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' is read-only"
              return 1
            fi
            ;;
          "int")
            if ! bg.str.is_int "$provided_arg"; then
            bg.err.print "string '$provided_arg' is not an integer"
              return 1
            fi
            ;;
          *)
            bg.err.print "Type prefix '${type_prefix}' for variable '$required_arg' is not valid. Valid prefixes are: 'ra', 'rwa', and 'int'"
            return 1
            ;;
        esac
      fi

      # sanitize arguments in provided_args by replacing all single quotes(')
      # in the arg with escaped single quotes to avoid arbitrary code execution
      eval "${required_arg}='$( bg.str.escape_single_quotes "${provided_arg}" )'"
    done
  fi

}


if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
  source arr.bash
  source env.bash
  source tty.bash
fi

################################################################################
# LOG CONSTANTS 
################################################################################
__BG_LOG_DEFAULT_FORMAT="[%-5s][%s]: %s\n"
__BG_LOG_DEFAULT_OUT="&2"


################################################################################
# LOG FUNCTIONS
################################################################################
__bg.log.log() {
  local provided_log_level
  local message
  required_args=( 'provided_log_level' 'message' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  local BG_LOG_LEVEL="${BG_LOG_LEVEL:-FATAL}"
  local BG_LOG_FORMAT="${BG_LOG_FORMAT:-${__BG_LOG_DEFAULT_FORMAT}}"
  local -a LOG_LEVELS=( "TRACE" "DEBUG" "INFO" "WARN" "ERROR" "FATAL" )
  local -a LOG_COLOR=( "cyan" "magenta" "green" "yellow" "red" "red" )

  if ! bg.arr.is_member 'LOG_LEVELS' "$BG_LOG_LEVEL"; then
    bg.err.print "'${BG_LOG_LEVEL}' is not a valid log level. Valid values are: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', and 'FATAL'"
    return 1
  fi

  local -i provided_log_level_index  
  provided_log_level_index="$(bg.arr.index_of 'LOG_LEVELS' "$provided_log_level")"

  local -i env_log_level_index
  env_log_level_index="$(bg.arr.index_of 'LOG_LEVELS' "$BG_LOG_LEVEL")"

  local BG_LOG_OUT="${BG_LOG_OUT:-${__BG_LOG_DEFAULT_OUT}}"
  local log_out_without_fd_prefix="${BG_LOG_OUT#&}"

  if (( env_log_level_index <= provided_log_level_index )); then
    local formatted_log_level
    formatted_log_level="$( 
      "bg.tty.${LOG_COLOR[$provided_log_level_index]}" \
      "$provided_log_level"
      )"

    # shellcheck disable=SC2059
    if [[ "${log_out_without_fd_prefix}" != "${BG_LOG_OUT}" ]]; then
      #shellcheck disable=SC2059
      printf "${BG_LOG_FORMAT}" "$( bg.env.get_parent_script_name )" "$formatted_log_level" "$message" >&"$log_out_without_fd_prefix"
    else
      #shellcheck disable=SC2059
      printf "${BG_LOG_FORMAT}" "$( bg.env.get_parent_script_name )" "$formatted_log_level" "$message" >>"${BG_LOG_OUT}"
    fi

  fi
}

bg.log.trace() {
  local message
  required_args=( 'message' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi
  
  __bg.log.log "TRACE" "$message"
}

bg.log.debug() {
  local message
  required_args=( 'message' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi
  
  __bg.log.log "DEBUG" "$message"
}

bg.log.info() {
  local message
  required_args=( 'message' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi
  
  __bg.log.log "INFO" "$message"
}

bg.log.warn() {
  local message
  required_args=( 'message' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi
  
  __bg.log.log "WARN" "$message"
}

bg.log.error() {
  local message
  required_args=( 'message' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi
  
  __bg.log.log "ERROR" "$message"
}

bg.log.fatal() {
  local message
  required_args=( 'message' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi
  
  __bg.log.log "FATAL" "$message"
}

################################################################################
# STRING FUNCTIONS
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
bg.str.is_valid_var_name() ( 
  local re="^[a-zA-Z_][a-zA-Z0-9_]*$"
  if [[ "${1:-}" =~ $re ]]; then
    return 0
  else
    return 1
  fi
)

# description: |
#   returns 0 if the first argument is an integer and eturns 1 otherwise.
# inputs:
#   stdin:
#   args:
#    1: "first command-line argument"
#    rest: all other parameters are ignored 
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "if the first arg is an integer"
#     1: "otherwise"
bg.str.is_int() {
  local re='^[0-9]+$'
  if ! [[ "${1:-}" =~ $re ]]; then
    return 1
  fi
}

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
bg.str.is_valid_command() ( 
  local command_type
  if ! command_type="$(type -t "${1:-}" 2>/dev/null)"; then
    return 1
  fi

  if [[ "$command_type" = "keyword" ]] ; then
    return 1
  fi
)

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
bg.str.is_valid_shell_opt() { 
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
bg.str.is_valid_bash_opt() ( 
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
)


# description: |
#   prints the given string to stdout with any single quotes escaped so the
#   string itself can be put inside single quotes
# inputs:
#   stdin:
#   args:
#     1: "string to sanitize"
# outputs:
#   stdout: "string with escaped single quotes"
#   stderr:
#   return_code:
#     0: "when the string is a valid bash option in the current bash"
#     2: "when the required string is not provided"
# tags:
#   - "option decorators"
# examples:
# - script: |
#     string_to_print="Today's date is Monday"
#     escaped_string="$(bg.str.escape_single_quotes "$string_to_print")"
#     eval "echo '$escaped_string'"
#   output:
#     Today's date is Monday 
bg.str.escape_single_quotes() ( 
  local string
  string="${1:-}"
  string="${string//\'/\'\\\'\'}"
  printf "%s" "$string"
)

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
  source err.bash
  source arr.bash
fi

################################################################################
# OUTPUT FUNCTIONS
################################################################################
__bg.tty.tty() {
  local format
  local string
  required_args=( 'format' 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # TODO: convert this into associative array
  # Available formats
  local -a available_formats=(
    'black'
    'red'
    'green'
    'yellow'
    'blue'
    'magenta'
    'cyan'
    'white'
    'bold'
  )

  local -a escape_sequences=(
    '\e[0;30m'
    '\e[0;31m'
    '\e[0;32m'
    '\e[0;33m'
    '\e[0;34m'
    '\e[0;35m'
    '\e[0;36m'
    '\e[0;37m'
    '\e[1m'
  )

  format_lowercase="${format,,}"
  format_uppercase="${format^^}"

  if ! bg.arr.is_member 'available_formats' "${format_lowercase}"; then
    bg.err.print "'$format' is not a valid formatting. Valid options are: $( bg.arr.itemize 'available_formats' )"
    return 1
  fi

  if bg.var.is_set 'BG_NO_TTY'; then
    printf '%s\n' "${string}"
    return 0
  fi

  local -i index
  index="$(bg.arr.index_of 'available_formats' "${format_lowercase}")"

  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local env_var_name="__BG_FORMAT_${format_uppercase}"
  eval "$env_var_name=\"\${${env_var_name}:-${escape_sequences[$index]}}\""

  # shellcheck disable=SC2031 
  printf "${!env_var_name}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.tty.black() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "BLACK" "$string"
}

bg.tty.red() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "RED" "$string"
}

bg.tty.green() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "GREEN" "$string"
}

bg.tty.yellow() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "YELLOW" "$string"
}

bg.tty.blue() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "BLUE" "$string"
}

bg.tty.magenta() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "MAGENTA" "$string"
}

bg.tty.cyan() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "CYAN" "$string"
}

bg.tty.white() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "WHITE" "$string"
}

bg.tty.bold() {
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2031
  __bg.tty.tty "BOLD" "$string"
}

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
fi

################################################################################
# VARIABLE FUNCTIONS 
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
bg.var.is_array() ( 
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (array_name) is required but was not provided"
    return 2
  fi
  local array_name="${1}"  
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
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (var_name) is required but was not provided"
    return 2
  fi
  local var_name="${1}"

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
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (var_name) is required but was not provided"
    return 2
  fi
  # shellcheck disable=SC2030
  local var_name="${1}" 
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
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (var_name) is required but was not provided"
    return 2
  fi
  # shellcheck disable=SC2030
  local var_name="${1}" 

  if ! bg.var.is_declared "$var_name"; then
    return 1
  fi

  regex='^declare -[a-zA-Z-]+ [a-zA-Z_][a-zA-Z0-9_]*\=.+$'
  if ! [[ "$( declare -p "$var_name" )" =~ $regex ]]; then
    return 1 
  fi
)


