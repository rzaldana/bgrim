source in.bash

################################################################################
# STRING FUNCTIONS
################################################################################

# Checks if the given string is a valid variable name (i.e. it's made up 
# exclusively of alphanumeric characters and underscores and it does not start
# with a number
# Globals:
#   None
# Arguments:
#   String to evaluate
# Outputs:
#   None
# Returns:
#   0 if the given string is a valid variable name 
#   1 otherwise
bg.str.is_valid_var_name() ( 
  local var_name
  local -a required_args=( "var_name" )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  local re="^[a-zA-Z_][a-zA-Z0-9_]*$"
  if [[ "$var_name" =~ $re ]]; then
    return 0
  else
    return 1
  fi
)

# description: |
#   returns 0 if the first argument refers to a function, shell built-in, or
#   an executable in the PATH. Returns 1 otherwise.
# inputs:
#   stdin:
#   args:
#    1: "first command-line argument"
#    rest: all other parameters are ignored 
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "if the first arg is a function, shell built-in or executable in PATH"
#     1: "otherwise"
# tags:
#   - "syntax_sugar"
bg.str.is_valid_command() ( 
  local command_name
  local -a required_args=( 'command_name' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  local command_type
  command_type="$(type -t "$command_name" 2>/dev/null)"
  local ret_code="$?"

  [[ "$ret_code" != 0 ]] && return 1 
  [[ "$command_type" = "keyword" ]] && return 1
  return 0
)

# description: |
#   returns 0 if the given string is a valid option name that can be set with the
#   'set -o [option name]' command. This command ony works with long option names
# inputs:
#   stdin:
#   args:
#     1: "string to evaluate"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "when the string is a valid shell option in the current bash"
#     1: "when the string is not a valid shell option in the current bash"
# tags:
#   - "option decorators"
bg.str.is_valid_shell_opt() ( 
  local opt_name
  local opt_name_iterator
  local opt_value

  local -a required_args=( 'opt_name' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  opt_name="${1:-}"

  # shellcheck disable=SC2034
  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    [[ "$opt_name" == "$opt_name_iterator" ]] \
      && return 0
  done < <(set -o 2>/dev/null)
  return 1
)

# description: |
#   returns 0 if the given string is a valid option name that can be set with the
#   'shopt -s [option name]' command.
# inputs:
#   stdin:
#   args:
#     1: "string to evaluate"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "when the string is a valid bash option in the current bash"
#     1: "when the string is not a valid bash option in the current bash"
# tags:
#   - "option decorators"
bg.str.is_valid_bash_opt() ( 
  local opt_name
  local opt_name_iterator
  local opt_value
  local -a required_args=( 'opt_name' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # shellcheck disable=SC2034
  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    [[ "$opt_name" == "$opt_name_iterator" ]] \
      && return 0
  done < <(shopt 2>/dev/null)
  return 1
)


# description: |
#   prints the given string to stdout with any single quotes escaped so the
#   string itself can be put inside single quotes
# inputs:
#   stdin:
#   args:
#     1: "string to sanitize"
# outputs:
#   stdout: "string with escaped single quotes"
#   stderr:
#   return_code:
#     0: "when the string is a valid bash option in the current bash"
#     2: "when the required string is not provided"
# tags:
#   - "option decorators"
# examples:
# - script: |
#     string_to_print="Today's date is Monday"
#     escaped_string="$(bg.str.escape_single_quotes "$string_to_print")"
#     eval "echo '$escaped_string'"
#   output:
#     Today's date is Monday 
bg.str.escape_single_quotes() ( 
  local string
  local -a required_args=( 'string' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  string="${string//\'/\'\\\'\'}"
  printf "%s" "$string"
)
