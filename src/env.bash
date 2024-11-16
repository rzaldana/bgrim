if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
  source str.bash
  source var.bash
  source arr.bash
fi

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

__bg.env.get_stackframe() {
  local -i frame
  local -a out_arr
  local -a required_args=( "int:frame" "rwa:out_arr" )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # empty out arr
  eval "$out_arr=()"

  local -i funcname_arr_len="${#FUNCNAME[@]}"
  if (( frame+2 >= funcname_arr_len )); then
    bg.err.print "requested frame '${frame}' but there are only frames 0-$((funcname_arr_len-3)) in the call stack"
    return 1
  fi
  local line_no_index=$(( frame + 1 ))
  local funcname_index=$(( frame + 2 ))
  local bash_source_index=$(( frame + 2 ))
  eval "${out_arr}+=( '${BASH_LINENO[line_no_index]}' )"
  eval "${out_arr}+=( '${FUNCNAME[funcname_index]}' )"
  eval "${out_arr}+=( '${BASH_SOURCE[bash_source_index]}' )"
}

__bg.env.format_stackframe() {
  local stackframe_array
  local -a required_args=( "ra:stackframe_array" )  
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Get lenght of stackframe array
  local array_length
  eval "array_length=\${#${stackframe_array}[@]}"

  # check that stackframe array has at least 3 elements
  if (( array_length < 3 )); then
    bg.err.print "array '${stackframe_array}' has less than 3 elements"
    return 1
  fi

  # check that stackframe array has at most 3 elements
  if (( array_length > 3 )); then
    bg.err.print "array '${stackframe_array}' has more than 3 elements"
    return 1
  fi

  local funcname
  local filename
  local lineno
  eval "lineno=\"\${${stackframe_array}[0]}\""
  eval "funcname=\"\${${stackframe_array}[1]}\""
  eval "filename=\"\${${stackframe_array}[2]}\""
  printf '  at %s (%s:%s)\n' "$funcname" "$filename" "$lineno"
}
__bg.env.print_stacktrace() {
  # shellcheck disable=SC2034
  local -i requested_frame
  local -a required_args=( "int:requested_frame" )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  local -a stackframe=()
  while __bg.env.get_stackframe "$requested_frame" 'stackframe' 2>/dev/null; do
    __bg.env.format_stackframe 'stackframe'
  done
}

__bg.env.get_stderr_line() {
  if ! bg.var.is_set '__bg_env_stderr_capture_read_fd'; then
    bg.err.print "stderr capturing process hasn't been started yet"
    return 1
  fi
  kill -s SIGUSR1 "${__bg_env_stderr_capture_pid}"
  local stderr_line
  read -ru "${__bg_env_stderr_capture_read_fd}" stderr_line
  if [[ "$stderr_line" == "__bg_env_stderr_capture: stderr is empty" ]]; then
    bg.err.print "stderr is empty"
    return 1
  fi
  echo "$stderr_line"
}

__bg.env.start_stderr_capturing() {
  coproc __bg_env_stderr_capture {
    trap - DEBUG
    declare -a captured_lines=()
    declare -i index
    declare -i captured_lines_len
    trap '{ 
      captured_lines_len="$( bg.arr.length captured_lines )"
      if (( captured_lines_len == 0 )); then
        echo "__bg_env_stderr_capture: stderr is empty"
        return 0
      fi
      echo "${captured_lines[-1]}";
      unset "captured_lines[-1]";
    }' SIGUSR1
    # read from stdin into captured_lines array
    while IFS= read -r line; do
      # shellcheck disable=SC2031
      captured_lines+=( "${line}" )
    done
  }
  declare -g __bg_env_stderr_capture_read_fd="${__bg_env_stderr_capture[0]}"
  # shellcheck disable=SC2154
  declare -g __bg_env_stderr_capture_pid="${__bg_env_stderr_capture_PID}"
  exec 2>&"${__bg_env_stderr_capture[1]}"
}

__bg.env.start_stderr_enriching() {
  set -o functrace
  trap '
    echo "__bg_env_stderr_enriching: command:${BASH_COMMAND}" >&2
  ' DEBUG
  # Make DEBUG trap be inherited by shell functions,
  # command substitutions, and subshells
}

__bg.env.get_stderr_for_command() {
  local -a required_args=( "command" "rwa:output_arr" )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  local line
  local -a pre_output_arr
  local found_command="false"
  while line="$(__bg.env.get_stderr_line 2>/dev/null)"; do
    if [[ "$line" != "__bg_env_stderr_enriching: command:${command}" ]]; then
      # filter out all enriched lines
      local re="__bg_env_stderr_enriching:*"
      if ! [[ "$line" =~ $re ]]; then
        pre_output_arr+=( "${line}" )
      fi
    else
      found_command="true"
    fi
  done

  if [[ "$found_command" != "true" ]]; then
    bg.err.print "could not find stderr messages for command '$command'"
    return 1
  fi

  # Reverse pre_output_arr
  pre_output_arr_len="$( bg.arr.length 'pre_output_arr' )"
  local -i i=$(( pre_output_arr_len - 1 ))
  while (( i >= 0 )); do
    # shellcheck disable=SC2154
    eval "${output_arr}+=( '${pre_output_arr[$i]}' )"
    (( i-- )) || : 
  done
}
