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
  local re="^[a-zA-Z_][a-zA-Z0-9_]*$"
  if [[ "${1:-}" =~ $re ]]; then
    return 0
  else
    return 1
  fi
)

# description: |
#   returns 0 if the first argument is an integer and eturns 1 otherwise.
# inputs:
#   stdin:
#   args:
#    1: "first command-line argument"
#    rest: all other parameters are ignored 
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "if the first arg is an integer"
#     1: "otherwise"
bg.str.is_int() {
  local re='^[0-9]+$'
  if ! [[ "${1:-}" =~ $re ]]; then
    return 1
  fi
}

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
bg.str.is_valid_command() ( 
  local command_type
  if ! command_type="$(type -t "${1:-}" 2>/dev/null)"; then
    return 1
  fi

  if [[ "$command_type" = "keyword" ]] ; then
    return 1
  fi
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
bg.str.is_valid_shell_opt() { 
  local opt_name
  local opt_name_iterator
  local opt_value

  opt_name="${1:-}"

  # shellcheck disable=SC2034
  while IFS=$' \t\n' read -r opt_name_iterator opt_value; do
    [[ "$opt_name" == "$opt_name_iterator" ]] \
      && return 0
  done < <(set -o 2>/dev/null)
  return 1
}

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
  opt_name="${1:-}"
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
  string="${1:-}"
  string="${string//\'/\'\\\'\'}"
  printf "%s" "$string"
)
