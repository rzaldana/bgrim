source in.bash
source arr.bash
source env.bash

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
  local -a LOG_LEVELS=( "TRACE" "DEBUG" "INFO" "WARN" "ERROR" "FATAL" )

  if ! bg.arr.is_member 'LOG_LEVELS' "$BG_LOG_LEVEL"; then
    bg.err.print "'${BG_LOG_LEVEL}' is not a valid log level. Valid values are: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', and 'FATAL'"
    return 1
  fi

  local -i provided_log_level_index  
  provided_log_level_index="$(bg.arr.index_of 'LOG_LEVELS' "$provided_log_level")"

  local -i env_log_level_index
  env_log_level_index="$(bg.arr.index_of 'LOG_LEVELS' "$BG_LOG_LEVEL")"

  if (( env_log_level_index <= provided_log_level_index )); then
    printf "[%-5s][%s]: %s\n" "$provided_log_level" "$( bg.env.get_parent_script_name )" "$message" >&2
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
