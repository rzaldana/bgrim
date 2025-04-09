if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
fi

################################################################################
# Functions for manipulating TTY display 
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
