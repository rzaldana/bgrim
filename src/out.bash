source in.bash

################################################################################
# OUTPUT FUNCTIONS
################################################################################
__bg.fmt.fmt() {
  local format
  local string
  required_args=( 'format' 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Format constants
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local __BG_FORMAT_BLACK="${__BG_FORMAT_BLACK:-\e[0;30m}"
  local __BG_FORMAT_RED="${__BG_FORMAT_RED:-\e[0;31m}"
  local __BG_FORMAT_GREEN="${__BG_FORMAT_GREEN:-\e[0;32m}"
  local __BG_FORMAT_YELLOW="${__BG_FORMAT_YELLOW:-\e[0;33m}"
  local __BG_FORMAT_BLUE="${__BG_FORMAT_BLUE:-\e[0;34m}"
  local __BG_FORMAT_MAGENTA="${__BG_FORMAT_MAGENTA:-\e[0;35m}"
  local __BG_FORMAT_CYAN="${__BG_FORMAT_CYAN:-\e[0;36m}"
  local __BG_FORMAT_WHITE="${__BG_FORMAT_WHITE:-\e[0;37m}"
  local __BG_FORMAT_BOLD="${__BG_FORMAT_BOLD:-\e[1m}"

  local format_var
  format_var="__BG_FORMAT_${format}"
  
  printf "${!format_var}%s${__BG_FORMAT_BLANK}\n" "$string"

}

bg.out.format_black() {
  local __BG_FORMAT_BLACK="${__BG_FORMAT_BLACK:-\e[0;30m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_BLACK=""
    __BG_FORMAT_BLANK=""
  fi
    
  printf "${__BG_FORMAT_BLACK}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_red() {
  local __BG_FORMAT_RED="${__BG_FORMAT_RED:-\e[0;31m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_RED=""
    __BG_FORMAT_BLANK=""
  fi
    
  printf "${__BG_FORMAT_RED}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_green() {
  # red constant
  local __BG_FORMAT_GREEN="${__BG_FORMAT_GREEN:-\e[0;32m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_GREEN=""
    __BG_FORMAT_BLANK=""
  fi

  printf "${__BG_FORMAT_GREEN}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_yellow() {
  local __BG_FORMAT_YELLOW="${__BG_FORMAT_YELLOW:-\e[0;33m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_YELLOW=""
    __BG_FORMAT_BLANK=""
  fi

  printf "${__BG_FORMAT_YELLOW}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_blue() {
  local __BG_FORMAT_BLUE="${__BG_FORMAT_BLUE:-\e[0;34m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_BLUE=""
    __BG_FORMAT_BLANK=""
  fi

  printf "${__BG_FORMAT_BLUE}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_magenta() {
  local __BG_FORMAT_MAGENTA="${__BG_FORMAT_MAGENTA:-\e[0;35m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_MAGENTA=""
    __BG_FORMAT_BLANK=""
  fi

  printf "${__BG_FORMAT_MAGENTA}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_cyan() {
  local __BG_FORMAT_CYAN="${__BG_FORMAT_CYAN:-\e[0;36m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_CYAN=""
    __BG_FORMAT_BLANK=""
  fi

  printf "${__BG_FORMAT_CYAN}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_white() {
  local __BG_FORMAT_WHITE="${__BG_FORMAT_WHITE:-\e[0;37m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_WHITE=""
    __BG_FORMAT_BLANK=""
  fi

  printf "${__BG_FORMAT_WHITE}%s${__BG_FORMAT_BLANK}\n" "$string"
}

bg.out.format_bold() {
  local __BG_FORMAT_BOLD="${__BG_FORMAT_BOLD:-\e[1m}"
  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local string
  required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if bg.var.is_set 'BG_NO_FORMAT'; then
    __BG_FORMAT_BOLD=""
    __BG_FORMAT_BLANK=""
  fi

  printf "${__BG_FORMAT_BOLD}%s${__BG_FORMAT_BLANK}\n" "$string"
}
