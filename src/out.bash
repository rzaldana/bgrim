source in.bash
source err.bash
source arr.bash

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

  local -i index
  index="$(bg.arr.index_of 'available_formats' "${format_lowercase}")"

  local __BG_FORMAT_BLANK="${__BG_FORMAT_BLANK:-\e[0m}"
  local env_var_name="__BG_FORMAT_${format_uppercase}"
  eval "$env_var_name=\"\${${env_var_name}:-${escape_sequences[$index]}}\""

  # shellcheck disable=SC2031 
  printf "${!env_var_name}%s${__BG_FORMAT_BLANK}\n" "$string"
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
