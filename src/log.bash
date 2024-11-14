source in.bash
source arr.bash
source env.bash
source tty.bash

################################################################################
# LOG CONSTANTS 
################################################################################
declare -A __BG_LOG_CONSTANTS=(
  [__BG_LOG_DEFAULT_FORMAT]="[%-5s][%s]: %s\n"
  [__BG_LOG_DEFAULT_OUT]="&2"
)


for constant in "${!__BG_LOG_CONSTANTS[@]}"; do
  if [[ -z "${__BG_TEST_MODE:-}" ]]; then
    readonly "${constant}=${__BG_LOG_CONSTANTS[$constant]}" 
  else
    declare -g "${constant}=${__BG_LOG_CONSTANTS[$constant]}" 
  fi
done


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
      printf "${BG_LOG_FORMAT}" "$( bg.env.get_parent_script_name )" "$formatted_log_level" "$message" >"${BG_LOG_OUT}"
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
