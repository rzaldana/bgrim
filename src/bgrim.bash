#!/usr/bin/env bash

source "in.bash"

# Copyright (c) 2024 Raul Armando Zaldana Calles

################################################################################
##############       ######      ###       #####  ###         ##################
#############         ####       ##         ###   ##           #################
#############   ###    ##    ######   ###    ##   ##   #   #   #################
#############   ####   ##   #######   ####   ##   ##   #####   #################
#############   #      ##   #######   ####   ##   ##   #####   #################
#############   ##    ###   #######   ###    ##   ##   #####   #################
#############   ####   ##   #######         ###   ##   #####   #################
#############   ####   ##   #    ##         ###   ##   #####   #################
#############   ####   ##   #    ##   ###    ##   ##   #####   #################
#############   ####   ##   ###  ##   ####   ##   ##   #####   #################
#############   #     ####       ##   ####   ##   ##   #####   #################
#############   ##   ######      ##   ####   ##   ##   #####   #################
#############  ####################  ##########  ###########  ##################
############# ##################### ########### ############ ###################
################################################################################

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


################################################################################
# EMPTY COMMENT TEMPLATE
################################################################################
# description:
# inputs:
#   stdin:
#   args:
# #   1: "first command-line argument"
# #   2: "second command-line argument"
# #   rest: arguments 4 and above are interpreted the same way 
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "description of when the function returns status code 0"
#     1: "description of when the function returns status code 1"
# tags:
#   - "syntax_sugar"
################################################################################

################################################################################
# CONSTANTS
################################################################################
export __BG_MKTEMP="mktemp"


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
    && printf '%s\n' "ERROR: arg1 (prefix) is empty but is required" >&2 \
    && return 1

  # Check that prefix is a valid variable name
  if ! bg.str.is_valid_var_name "$prefix"; then \
    printf '%s\n' "ERROR: '$prefix' is not a valid variable prefix" >&2
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
    && echo "'$opt_name' is not a valid shell option" >&2 \
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


################################################################################
# Description: Checks if a function with the given name exists
# Globals:
#   None
# inputs:
#   stdin:
#   args:
#     1: "function_name"
# outputs:
#   stdout:
#   stderr: error message if no args are provided
#   return_code:
#     0: "if arg1 is a string of length 0 or is not provided"
#     1: "if arg1 is a string of length more than 1"
# tags:
#   - "syntax_sugar"
# Returns:
#   0: if the given value refers to a function in the environment 
#   1: if no function with the given name exists in the environment 
#   2: if no arguments are provided 
################################################################################
bg.func.is_declared() ( 
  local function_name
  local -a required_args=( 'function_name' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  if declare -f "$function_name" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
)



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

# description: |
#   Creates a temporary file using 'mktemp' and sets an EXIT trap for
#   the file to be deleted upon exit of the current shell process. It
#   takes the name of a variable as it's only argument and places the
#   path to the temporary file in the variable whose name is provided.
# inputs:
#   stdin:
#   args:
#     1: filename variable
# outputs:
#   stderr:
#   return_code:
#     0: "if the file was successfully created and the exit trap set"
#     1: "if there was an error while creating the file or setting the trap"
# dependencies:
# tags:
#   - "error_handling" 
bg.tmpfile.new() {
  local filename_var
  local -a required_args=( 'filename_var' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Validate that filename_var is a valid variable name
  if ! bg.str.is_valid_var_name "$filename_var"; then
    echo "ERROR: '$filename_var' is not a valid variable name" >&2
    return 1
  fi

  local tmpfile_name
  tmpfile_name="$("$__BG_MKTEMP")" \
    || { echo "ERROR: Unable to create temporary file" >&2; return 1; }
  bg.trap.add "rm -f '$tmpfile_name'" 'EXIT' \
    || { echo "ERROR: Unable to set exit trap to delete file '$tmpfile_name'" >&2; return 1; }

  # Assign name of tmpfile to variable whose name is contained in
  # filename_var
  eval "$filename_var=$tmpfile_name"
}

################################################################################
# CLI FUNCTIONS
################################################################################
__bg.cli.sanitize_string() {
  local string
  local -a required_args=( "string" )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Escape any backslashes (\)
  string="${string//\\/\\\\}"

  # Escape any pipe (|) characters
  string="${string//\|/\\\|}" 

  printf '%s' "$string"
}

__bg.cli.stdin_to_stdout() {
  while IFS= read -r line; do
    printf "%s\n" "$line"
  done
}

bg.cli.init() {
  printf "%s\n" 'init'
}

# description: |
#   reads a cli spec on stdin and prints the spec to stdout
#   with a new line detailing the that contains the description 
#   that the cli tool will print in its help message
# inputs:
#   stdin: an argparse spec 
#   args:
#     1: "cli description"
# outputs:
#   stdout: cli spec with added description
#   stderr:
#   return_code:
#     0: "when new line was successfully added to spec"
#     1: "when an error ocurred"
# tags:
#   - "cli parsing"
bg.cli.add_description() {
  # Check required input args
  local description
  required_args=( "description" )
  if ! bg.in.require_args "$@"; then
    return 2 
  fi

  # read cli spec from stdin and print to stdout
  __bg.cli.stdin_to_stdout

  # sanitize description string
  description="$(__bg.cli.sanitize_string "$description")"

  # add new spec line with description
  printf "%s|%s\n" "desc" "$description"
}

# description: |
#   reads a cli spec on stdin and prints the spec to stdout
#   with a new line detailing the configuration of the new flag
#   defined through the command-line parameters
# inputs:
#   stdin: an argparse spec 
#   args:
#     1: "option letter"
#     2: "environment variable where value of flag will be stored"
#     3: "help message for flag"
# outputs:
#   stdout:
#   stderr: |
#     error message if validation of arguments fails
#   return_code:
#     0: "when new line was successfully added to spec"
#     1: "when an error ocurred"
# tags:
#   - "cli parsing"
bg.cli.add_opt() {
  # Check number of arguments
  local opt_letter
  local env_var
  local help_message
  local -a required_args=( "opt_letter" "env_var" "help_message" )
  if ! bg.in.require_args "$@"; then
    return 2 
  fi

  # Validate arguments
  if ! [[ "$opt_letter" =~ ^[a-z]$ ]]; then
    echo "ERROR: option letter '$opt_letter' should be a single lowercase letter" >&2
    return 1
  fi

  if ! bg.str.is_valid_var_name "$env_var"; then
    echo "ERROR: '$env_var' is not a valid variable name" >&2
    return 1
  fi

  if bg.var.is_readonly "$env_var"; then
    echo "ERROR: '$env_var' is a readonly variable" >&2
    return 1
  fi

  help_message="$(__bg.cli.sanitize_string "$help_message")"

  # Print all lines from stdin to stdout 
  __bg.cli.stdin_to_stdout

  # Print new spec line
  printf '%s|%s|%s|%s\n' 'opt' "$opt_letter" "$env_var" "$help_message"
}


# description: |
#   reads a cli spec on stdin and prints the spec to stdout
#   with a new line detailing the configuration of the new flag
#   defined through the command-line parameters
# inputs:
#   stdin: an argparse spec 
#   args:
#     1: "option letter"
#     2: "environment variable where value of flag will be stored"
#     3: "help message for flag"
# outputs:
#   stdout:
#   stderr: |
#     error message if validation of arguments fails
#   return_code:
#     0: "when new line was successfully added to spec"
#     1: "when an error ocurred"
# tags:
#   - "cli parsing"
bg.cli.add_opt_with_arg() {
  # Check number of arguments
  local opt_letter
  local env_var
  local help_message
  local -a required_args=( "opt_letter" "env_var" "help_message" )
  if ! bg.in.require_args "$@"; then
    return 2 
  fi

  # Validate arguments
  if ! [[ "$opt_letter" =~ ^[a-z]$ ]]; then
    echo "ERROR: option letter '$opt_letter' should be a single lowercase letter" >&2
    return 1
  fi

  if ! bg.str.is_valid_var_name "$env_var"; then
    echo "ERROR: '$env_var' is not a valid variable name" >&2
    return 1
  fi

  if bg.var.is_readonly "$env_var"; then
    echo "ERROR: '$env_var' is a readonly variable" >&2
    return 1
  fi

  # Escape any backslashes (\) in help message
  #help_message="${help_message//|/\\\\\\}"
  help_message="${help_message//\\/\\\\}"

  # Escape any pipe (|) characters in help message
  help_message="${help_message//\|/\\\|}"

 
  # Print all lines from stdin to stdout 
  while IFS= read -r line; do
    printf "%s\n" "$line"
  done


  # Print new spec line
  printf '%s|%s|%s|%s\n' 'opt_with_arg' "$opt_letter" "$env_var" "$help_message"
}

bg.cli.add_arg() {
  local arg_name
  local -a required_args
  required_args=( "arg_name" )

  # Check required input arguments
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Validate that 'arg_name' is a valid variable name
  if ! bg.str.is_valid_var_name "$arg_name"; then
    echo "ERROR: '$arg_name' is not a valid variable name" >&2
    return 1
  fi

  # Read lines from stdin and print to stdout
  __bg.cli.stdin_to_stdout

  # Print spec line
  printf '%s|%s\n' 'arg' "$arg_name"
}

bg.cli.parse() {
  # Store all spec lines from stdin
  # into an array called 'spec_array'
  local -a spec_array=()
  bg.arr.from_stdin 'spec_array'

  # Check that spec is not empty
  if [[ "${#spec_array[@]}" == '0' ]]; then
    echo "ERROR: argparse spec is empty" >&2
    return 1
  fi

  # Create spec table
  # Spec table is just a collection of 
  # arrays where the same index across
  # all arrays contains the data for a
  # record. Each record represents an
  # option spec.
  local -a opt_letters=()
  local -a opt_env_vars=()
  local -a opt_help_messages=()
  local -a opt_help_summaries=()
  local -a opt_has_args=()
  local -a args=()
  local description

  local getopts_spec=""



  for line_no in "${!spec_array[@]}"; do
    local line
    line="${spec_array[$line_no]}"

    # Check that first command is 'init'
    if [[ "$line_no" -eq 0 ]]; then
      if [[ "$line" != "init" ]]; then
        echo "ERROR: Invalid argparse spec. Line 0: should be 'init' but was '$line'" >&2
        return 1
      fi
      continue
    fi

    # Read line command (i.e. first word before the fist pipe char)
    read -d '|' line_command <<<"$line"

    # Remove line command from line
    line="${line#"${line_command}|"}"


    case "$line_command" in
      opt)
        local letter 
        local env_var
        local help_message
        local help_summary
        IFS='|' read letter env_var help_message <<<"$line"
        opt_letters+=( "$letter" )
        opt_env_vars+=( "$env_var" )
        opt_help_messages+=( "$help_message" )
        opt_has_args+=( "false" )
        opt_help_summaries+=( "-$letter" )
        getopts_spec="${getopts_spec}${letter}"
        ;;
      opt_with_arg)
        local letter 
        local env_var
        local help_message
        local help_summary
        IFS='|' read letter env_var help_message <<<"$line"
        opt_letters+=( "$letter" )
        opt_env_vars+=( "$env_var" )
        opt_help_messages+=( "$help_message" )
        opt_has_args+=( "true" )
        opt_help_summaries+=( "-$letter $env_var" )
        getopts_spec="${getopts_spec}${letter}:"
        ;;
      arg)
        args+=( "$line" )
        ;;
      desc)
        description="$line"
        ;;
    esac
  done 


  ################################################################################
  # Generate cli help message
  ################################################################################
  # Get routine name to be displayed in help message
  local routine_name
  routine_name="$(bg.env.get_parent_routine_name)"

  # Find longest help summary so we can nicely align
  # auto-generated help message
  local -i max_help_summary_length=0
  for help_summary in "${opt_help_summaries[@]}"; do
    help_summary_length="${#help_summary}"
    if [[ "${help_summary_length}" -gt "${max_help_summary_length}" ]]; then
      max_help_summary_length="${help_summary_length}"
    fi
  done

  # Find longest env var name so we can align
  # auto-generated help message
  local -i max_env_var_length=0
  for env_var in "${opt_env_vars[@]}"; do
    env_var_length="${#env_var}"
    if [[ "${env_var_length}" -gt "${max_env_var_length}" ]]; then
      max_env_var_length="${env_var_length}"
    fi
  done

  # Get number of option specs and args to use
  # when creating the help message
  local -i n_opt_specs n_arg_specs
  n_opt_specs="${#opt_letters[@]}"
  n_arg_specs="${#args[@]}"

  # Create usage string
  local usage_string="$routine_name"
  if (( n_opt_specs != 0 )); then
    usage_string="${usage_string} [OPTIONS]"
  fi

  for arg in "${args[@]}"; do
    usage_string="${usage_string} $arg"
  done

  # Fill in help message template
  ## Emtpy IFS means no word splitting
  ## -d '' means read until end of file 
  local help_message
  IFS= read -d '' help_message << EOF || true
$(bg.out.format_bold "$routine_name")
$( if bg.var.is_set 'description'; then printf "\n%s" "$description"; fi)
$( if bg.var.is_set 'description'; then
     printf '\n%s' "Usage: $usage_string" 
   else 
     printf '%s' "Usage: $usage_string"
   fi
)
$( for (( i=0; i<n_opt_specs; i++  ));
    do
      if (( i == 0 )); then
        printf "\n%s\n" 'Options:'
      fi
      printf "  %-${max_help_summary_length}s %s\n"\
        "${opt_help_summaries[$i]}" \
        "${opt_help_messages[$i]}"
    done
)
$( for (( i=0; i<n_opt_specs; i++  ));
    do
      if (( i == 0 )); then
        printf "\n%s\n" 'Environment Variables:'
      fi
      printf "  %-${max_env_var_length}s %s\n"\
        "${opt_env_vars[$i]}" \
        "Same as setting '-${opt_letters[$i]}'"
    done
)
EOF

  # Process options
  local OPT
  local index
  local env_var
  while getopts ":${getopts_spec}" "OPT"; do
    # Check if option was not in spec
    if [[ "$OPT" == "?" ]]; then

      # If option was '-h', print help message and exit
      if [[ "$OPTARG" == "h" ]]; then
        printf "%s" "$help_message" >&2
        return 0
      else
      # Otherwise, print error message and exit
      echo "ERROR: '-$OPTARG' is not a valid option" >&2
        return 1
      fi
    fi


    # Print error if option that expected arg did
    # not get one
    if [[ "$OPT" == ":" ]]; then
      echo "ERROR: Option '-$OPTARG' expected an argument but none was provided" >&2
      return 1
    fi

    # find index of opt in opt_letters array
    index="$(bg.arr.index_of 'opt_letters' "$OPT")"

    # find env var that corresponds to option
    env_var="${opt_env_vars[$index]}"


    # set env var
    declare -g "$env_var"


    # if OPTARG is set, assign its value to env var
    if bg.var.is_set 'OPTARG'; then
      # Escape single quotes in OPTARG
      local sanitized_optarg
      sanitized_optarg="$(bg.str.escape_single_quotes "$OPTARG")"
      eval "$env_var='$sanitized_optarg'"
    fi

  done
  
  # Remove all processed options from args array
  shift $(( OPTIND - 1 ))

  # Error out if less arguments than required were provided
  if (( ${#} < n_arg_specs )); then
    echo "ERROR: Expected positional argument '${args[$#]}' was not provided" >&2
    return 1
  fi

  # Error out if more arguments than required were provided
  if (( ${#} > n_arg_specs )); then
    local -i u_arg_index=$(( n_arg_specs + 1 ))
    echo "ERROR: Unexpected positional argument: '${!u_arg_index}'" >&2
    return 1
  fi

  # Match every argument to its environment variable
  local arg_env_var
  local -i i=1
  local sanitized_arg
  for arg_env_var in "${args[@]}"; do
    arg="${!i}"
    declare -g "$arg_env_var"
    sanitized_arg="$(bg.str.escape_single_quotes "$arg")" 
    eval "$arg_env_var='$sanitized_arg'"
    (( i++ ))
  done
}

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
    echo "ERROR: '${BG_LOG_LEVEL}' is not a valid log level. Valid values are: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', and 'FATAL'" >&2
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
