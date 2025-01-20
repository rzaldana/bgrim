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
