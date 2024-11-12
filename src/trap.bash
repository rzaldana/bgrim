source in.bash
################################################################################
# TRAP FUNCTIONS
################################################################################

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
  if ! bg.in.require_args "$@"; then
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
  if ! bg.in.require_args "$@"; then
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

