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
