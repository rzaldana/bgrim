#!/usr/bin/env bash 

# Copyright (c) 2024 Raul Armando Zaldana Calles
# Source: https://github.com/rzaldana/bgrim

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
__bg_version='0.2.0'

################################################################################
# ERROR HANDLING CONSTANTS 
################################################################################
__BG_ERR_FORMAT='ERROR: %s\n'

################################################################################
# ERROR HANDLING FUNCTIONS 
################################################################################
# description: Prints a formatted error messag to stdoute
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
  #shellcheck disable=SC2059
  printf "${__BG_ERR_FORMAT}" "${1:-}" >&2 || :
)


if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source tty.bash
fi

################################################################################
# LOG CONSTANTS 
################################################################################
__BG_LOG_DEFAULT_FORMAT="[%-5s][%s]: %s\n"
__BG_LOG_DEFAULT_OUT="&2"

################################################################################
# HELPER FUNCTIONS 
################################################################################
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
__bg.log.get_parent_routine_name() {
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
__bg.log.get_parent_script_name() {
  # Get the length of FUNCNAME
  local -i funcname_length
  funcname_length="${#FUNCNAME[@]}" 

  local -i top_level_index
  top_level_index=$(( funcname_length - 1 ))
  printf "%s" "$( basename "${BASH_SOURCE[$top_level_index]}" )"
}


################################################################################
# LOG FUNCTIONS
################################################################################
__bg.log.log() {
  local provided_log_level
  local message

  # No need to validate args here as it's an internal function
  provided_log_level="$1"
  message="$2"

  local BG_LOG_LEVEL="${BG_LOG_LEVEL:-FATAL}"
  local BG_LOG_FORMAT="${BG_LOG_FORMAT:-${__BG_LOG_DEFAULT_FORMAT}}"
  local -a LOG_LEVELS=( "TRACE" "DEBUG" "INFO" "WARN" "ERROR" "FATAL" )
  local -a LOG_COLOR=( "cyan" "magenta" "green" "yellow" "red" "red" )

  # find index of BG_LOG_LEVEL in LOG_LEVELS array
  # and fail if value of BG_LOG_LEVEL is not found
  # in array
  local is_bg_log_level_valid="false"
  local -i env_log_level_index
  for i in "${!LOG_LEVELS[@]}"; do
    if [[ "${LOG_LEVELS[$i]}" == "${BG_LOG_LEVEL}" ]]; then
      is_bg_log_level_valid="true"
      env_log_level_index="$i"
    fi
  done

  if [[ "$is_bg_log_level_valid" != "true" ]]; then
    bg.err.print "'${BG_LOG_LEVEL}' is not a valid log level. Valid values are: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', and 'FATAL'"
    return 1
  fi


  # find index of provided log level in LOG_LEVELS array
  local -i provided_log_level_index  
  for i in "${!LOG_LEVELS[@]}"; do
    if [[ "${LOG_LEVELS[$i]}" == "${provided_log_level}" ]]; then
      provided_log_level_index="$i"
    fi
  done

  local BG_LOG_OUT="${BG_LOG_OUT:-${__BG_LOG_DEFAULT_OUT}}"
  local log_out_without_fd_prefix="${BG_LOG_OUT#&}"

  if (( env_log_level_index <= provided_log_level_index )); then
    local formatted_log_level
    formatted_log_level="$( 
      "bg.tty.${LOG_COLOR[$provided_log_level_index]}" \
      "$provided_log_level"
      )"

    local parent_script_name
    parent_script_name="$( __bg.log.get_parent_script_name )"
    # shellcheck disable=SC2059
    if [[ "${log_out_without_fd_prefix}" != "${BG_LOG_OUT}" ]]; then
      #shellcheck disable=SC2059
      printf "${BG_LOG_FORMAT}" "${parent_script_name}" "$formatted_log_level" "$message" >&"$log_out_without_fd_prefix"
    else
      #shellcheck disable=SC2059
      printf "${BG_LOG_FORMAT}" "${parent_script_name}" "$formatted_log_level" "$message" >>"${BG_LOG_OUT}"
    fi

  fi
}

bg.log.trace() {
  local message
  message="${1:-}"
  
  __bg.log.log "TRACE" "$message"
}

bg.log.debug() {
  local message
  message="${1:-}"
  
  __bg.log.log "DEBUG" "$message"
}

bg.log.info() {
  local message
  message="${1:-}"
  
  __bg.log.log "INFO" "$message"
}

bg.log.warn() {
  local message
  message="${1:-}"
  
  __bg.log.log "WARN" "$message"
}

bg.log.error() {
  local message
  message="${1:-}"
  
  __bg.log.log "ERROR" "$message"
}

bg.log.fatal() {
  local message
  message="${1:-}"
  
  __bg.log.log "FATAL" "$message"
}

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
fi

################################################################################
# OUTPUT FUNCTIONS
################################################################################
__bg.tty.tty() {
  local format
  local string
  local BG_NO_TTY="${BG_NO_TTY:-}"

  # No need to do input validation here as it's an internal function
  format="$1"
  string="$2"

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

  # check if the provided formatting is present in the available_formats array
  # and retrieve its index in the array
  local -i index
  local is_provided_format_available="false"
  for i in "${!available_formats[@]}"; do
    if [[ "${available_formats[$i]}" == "$format_lowercase" ]]; then
      is_provided_format_available="true"
      index="$i"
    fi
  done

  if [[ "$is_provided_format_available" != "true" ]]; then
    bg.err.print "'$format' is not a valid formatting. Valid options are: 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan' 'white' 'bold'"
    return 1
  fi

  # If BG_NO_TTY is set to a non-empty string,
  # omit any formatting
  if [[ -n "$BG_NO_TTY" ]]; then
    printf '%s\n' "${string}"
    return 0
  fi

  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local env_var_name="__BG_FORMAT_${format_uppercase}"
  eval "$env_var_name=\"\${${env_var_name}:-${escape_sequences[$index]}}\""

  # shellcheck disable=SC2031 
  printf "${!env_var_name}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.tty.black() {
  __bg.tty.tty "BLACK" "${1:-}"
}

bg.tty.red() {
  __bg.tty.tty "RED" "${1:-}"
}

bg.tty.green() {
  __bg.tty.tty "GREEN" "${1:-}"
}

bg.tty.yellow() {
  __bg.tty.tty "YELLOW" "${1:-}"
}

bg.tty.blue() {
  __bg.tty.tty "BLUE" "${1:-}"
}

bg.tty.magenta() {
  __bg.tty.tty "MAGENTA" "${1:-}"
}

bg.tty.cyan() {
  __bg.tty.tty "CYAN" "${1:-}"
}

bg.tty.white() {
  __bg.tty.tty "WHITE" "${1:-}"
}

bg.tty.bold() {
  __bg.tty.tty "BOLD" "${1:-}"
}

