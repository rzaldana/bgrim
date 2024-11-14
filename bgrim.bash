#!/usr/bin/env bash

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

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
  source in.bash
  source str.bash
fi

################################################################################
# ARRAY FUNCTIONS
################################################################################

# description: returns the length of the array with the given name
# inputs:
#   stdin:
#   args:
#    1: "name of array"
# outputs:
#   stdout: "length of array"
#   stderr: "error message, if any"
#   return_code:
#     0: "if length was retrieved with no problem"
#     1: "if there was a problem with the given args"
bg.arr.length() {
  # Verify input arguments
  local -a required_args=( 'ra:array_name' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  local -i array_length
  # shellcheck disable=SC2031
  eval "array_length=\"\${#${array_name}[@]}\""
  echo "$array_length"
}

################################################################################
# Checks if the given value exists in the array with the given name 
# Globals:
#   None
# Arguments:
#   Value to look for
#   Name of array to look through
# Outputs:
#   Writes error message to stderr if return code is not 0 or 1 
# Returns:
#   0 if the given value exists in the array with the given name
#   1 if the given value does not exist in the array with the given name
#   2 if there is no array in the environment with the given name
################################################################################
bg.arr.is_member() ( 
  local value
  local array_name
  local -a required_args=( 'ra:array_name' 'value' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Store values of array into a temporary local array
  #local -a tmp_array
  #eval "tmp_array=( \"\${${array_name}[@]}\")"

  # shellcheck disable=SC2030,SC2031
  array_name="${array_name}[@]"
  for elem in "${!array_name}" ; do
    [[ "$elem" == "$value" ]] && return 0
  done
  return 1
)

# description: |
#   reads lines from stdin and stores each line as an element
#   of the array whose name is provided in the first arg.
#   Lines are assumed to be separated by newlines
# inputs:
#   stdin: elements to store in array
#   args:
#     1: "array name"
# outputs:
#   stdout:
#   stderr: |
#     error message when array name is missing or array is readonly 
#   return_code:
#     0: "when lines were successfully stored in array"
#     1: "when an error ocurred"
# tags:
#   - "cli parsing"
bg.arr.from_stdin() {
  local array_name
  local -a required_args=( 'rwa:array_name' )
  if ! bg.in.require_args "$@"; then
    return 2
  fi

  # Empty array
  # shellcheck disable=SC2031
  eval "${array_name}=()"

  # Read lines from stdin
  # shellcheck disable=SC2034
  while IFS= read -r line; do
    # shellcheck disable=SC2031
    eval "${array_name}+=( \"\${line}\")"
  done
}

# description: |
#   Takes a string and the name of an array and prints 
#   the index of the string in the array, if the string
#   is an item an array. If the string is not a member
#   of the array or if the provided array name does not
#   refer to an existing array in the function's execution
#   environment, it returns 1 and prints an error message
#   to stderr
# inputs:
#   stdin: null 
#   args:
#     1: "array_name"
#     2: "item"
# outputs:
#   stdout: index of the provded item in the array
#   stderr: |
#     error message if validation of arguments fails,
#     if the given item is not a member of the array
#     or if the array does not exist 
#   return_code:
#     0: "when the item was found in the array"
#     1: "when an error ocurred"
# tags:
#   - "arrays"
bg.arr.index_of() {
  local array_name
  local item

  # Check number of arguments
  local -a required_args=( "ra:array_name" "item" )
  if ! bg.in.require_args "$@"; then
    return 2 
  fi


  local -i array_length
  # shellcheck disable=SC2031
  eval "array_length=\"\${#${array_name}[@]}\""

  local current_item
  local -i index="-1"
  for ((index=0; index<array_length; index++)); do
    # shellcheck disable=SC2031
    eval "current_item=\${${array_name}[$index]}" 
    if [[ "$current_item" == "$item" ]]; then
      printf "%s" "$index"
      return 0
    fi
  done

  # shellcheck disable=SC2031
  bg.err.print "item '$item' not found in array with name '$array_name'"
  return 1
}

# description: |
#   Takes the name of an array and prints the array's
#   elements to stdout as a list of quote-delimited,
#   comma-separated words with the last word separated
#   by the word "and". Useful for output messages
#   that print array items
# inputs:
#   stdin: null 
#   args:
#     1: "array_name"
# outputs:
#   stdout: itemized list of array items 
#   stderr: |
#     error message if validation of arguments fails
#     or if the array does not exist 
#   return_code:
#     0: "when the array was properly verbalized"
#     1: "when an error ocurred"
#     2: "when argument validation failed"
# tags:
#   - "arrays"
bg.arr.itemize() {
  local array_name

  # Check number of arguments
  local -a required_args=( "ra:array_name" )
  if ! bg.in.require_args "$@"; then
    return 2 
  fi

  local array_length
  array_length="$( bg.arr.length "$array_name" )"

  case "${array_length}" in
    0)
      ;;
    1)
      eval "echo \"'\${${array_name}[0]}'\""
      ;;
    2)
      eval "echo \"'\${${array_name}[0]}' and '\${${array_name}[1]}'\""
      ;;
    *)
      eval "\
        local i
        for (( i = 0; i < ${array_length}; i++ )); do
          if (( i + 1 == ${array_length} )); then
            printf \"and '%s'\" \"\${${array_name}[\$i]}\"
          else
            printf \"'%s', \" \"\${${array_name}[\$i]}\"
         fi
        done
      "
  esac
}

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
  source str.bash
  source var.bash
  source arr.bash
  source env.bash
  source tty.bash
fi

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
    bg.err.print "option letter '$opt_letter' should be a single lowercase letter"
    return 1
  fi

  if ! bg.str.is_valid_var_name "$env_var"; then
    bg.err.print "'$env_var' is not a valid variable name"
    return 1
  fi

  if bg.var.is_readonly "$env_var"; then
    bg.err.print "'$env_var' is a readonly variable"
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
    bg.err.print "option letter '$opt_letter' should be a single lowercase letter"
    return 1
  fi

  if ! bg.str.is_valid_var_name "$env_var"; then
    bg.err.print "'$env_var' is not a valid variable name"
    return 1
  fi

  if bg.var.is_readonly "$env_var"; then
    bg.err.print "'$env_var' is a readonly variable"
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
    bg.err.print "'$arg_name' is not a valid variable name"
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
    bg.err.print "argparse spec is empty"
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
        bg.err.print "Invalid argparse spec. Line 0: should be 'init' but was '$line'"
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
$(bg.tty.bold "$routine_name")
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
        bg.err.print "'-$OPTARG' is not a valid option"
        return 1
      fi
    fi


    # Print error if option that expected arg did
    # not get one
    if [[ "$OPT" == ":" ]]; then
      bg.err.print "Option '-$OPTARG' expected an argument but none was provided"
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
    bg.err.print "Expected positional argument '${args[$#]}' was not provided"
    return 1
  fi

  # Error out if more arguments than required were provided
  if (( ${#} > n_arg_specs )); then
    local -i u_arg_index=$(( n_arg_specs + 1 ))
    bg.err.print "Unexpected positional argument: '${!u_arg_index}'"
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

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
  source str.bash
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
    && bg.err.printf "arg1 (prefix) is empty but is required" \
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


################################################################################
# ERROR HANDLING CONSTANTS 
################################################################################
__BG_ERR_DEFAULT_OUT="&2"
__BG_ERR_DEFAULT_FORMAT='ERROR: %s\n'

################################################################################
# ERROR HANDLING FUNCTIONS 
################################################################################
# description: Prints a formatted error message. It will print error messages to
#   stderr by default but a different file or fd (if preceded by &) can be 
#   specified using the __BG_ERROR_OUT environment variable. The format of the 
#   error message can be customized by using the __BG_ERROR_FORMAT environment 
#   variable. __BG_ERROR_FORMAT accepts any of the format specifications 
#   that the printf shell built-in would take where the first non-format 
#   argument to printf is the error message.
# inputs:
#   stdin:
#   args:
#    1: "error message"
#   env_vars:
#     - name: "__BG_ERROR_FORMAT"
#       description: "formatting to apply to error messages"
#       default: "ERROR: %s\n"
#     - name: "__BG_ERROR_OUT"
#       description: "file where error messages will be written to"
#       default: "stderr"
# outputs:
#   stdout:
#   stderr:
#   return_code:
#     0: "always"
bg.err.print() ( 
  local err_default_format='ERROR: %s\n'
  local __BG_ERR_FORMAT="${__BG_ERR_FORMAT:-${__BG_ERR_DEFAULT_FORMAT}}"
  local __BG_ERR_OUT="${__BG_ERR_OUT:-${__BG_ERR_DEFAULT_OUT}}"
  local err_out_without_fd_prefix="${__BG_ERR_OUT#&}"
  if [[ "${err_out_without_fd_prefix}" != "${__BG_ERR_OUT}" ]]; then
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >&"$err_out_without_fd_prefix" || :
  else
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >"$err_out_without_fd_prefix" || :
  fi
)

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
fi

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

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
  source var.bash
fi

################################################################################
# INPUT FUNCTIONS
################################################################################

# description: |
#   This function is meant to ensure that a function receives all the arguments
#   it expects. It expects an array called 'required_args' to be set in its
#   environment and it takes all the arguments that a function receives as its
#   cli arguments. It checks if there is a cli argument for every entry in the 
#   'required_args' array and assigns the value of the cli argument to a variable
#   with the name of the required arg
# inputs:
#   stdin:
#   args:
#     rest: cli arguments to validate
#   environment:
#     required_args: an array with an entry for every required arg
# outputs:
#   stdout:
#   stderr: |
#     an error message if the required_args array is not set or is empty
#     an error message if a required_arg is not provided in the cli arguments
#   return_code:
#     0: "if all expected positional arguments are received"
#     1: "if an expected positional argument is not provided"
#     2: "the 'required_args' array is empty or not set"
# tags:
#   - "core_utils"
# examples:
#   - script: |
#
#       #!/usr/bin/env bash
#
#       source core.bash
#
#       set +e # do not exit on error
#
#       myfunc() {
#         local arg1 arg2
#         required_args=( arg1 arg2 )
#         if ! bg.in.require_args "$@" ; then
#           return 2
#         fi
#
#         echo "arg1=$arg1"
#         echo "arg2=$arg2"
#       }
#       
#       echo "Function invocation with all required arguments:"
#       echo "================================================"
#       myfunc "value1" "value2"
#       ret_code="$?"
#       echo "return code: $ret_code"
#       echo "Function invocation with required argument missing:"
#       echo "================================================"
#       myfunc "value1" 
#       ret_code="$?"
#       echo "return code: $ret_code"
#     output: |
#       Function invocation with all required arguments:
#       ================================================
#       arg1=value1
#       arg2=value2
#       return code: 0
#       Function invocation with required argument missing:
#       ================================================
#       ERROR: argument 2 (arg2) is required but was not provided
#       return code: 2
bg.in.require_args() {

  local calling_function
  calling_function="${FUNCNAME[1]}"

  # Fail if required_args array is not set 
  if ! bg.var.is_array 'required_args'; then
    bg.err.print "'required_args' array not found"
    return 2
  fi

  # Fail if required_args array is not set 
  if ! bg.var.is_set 'required_args'; then
    bg.err.print "'required_args' array is empty"
    return 2
  fi

  local -a provided_args=( "$@" )

  # Validate that required args are all valid variable names
  local valid_var_name_re="^[a-zA-Z_][a-zA-Z0-9_]+$"
  for arg in "${required_args[@]}"; do
    # Remove type prefix, if present
    arg="${arg##*:}"
    if ! [[ "$arg" =~ $valid_var_name_re ]]; then
      bg.err.print "'$arg' is not a valid variable name"
      return 1
    fi
  done

  # Check that there is a cli argument for every required arg
  if [[ "${#provided_args[@]}" -lt "${#required_args[@]}" ]]; then
    bg.err.print "argument $(( ${#provided_args[@]} + 1 )) (${required_args[${#provided_args[@]}]}) is required but was not provided"
    return 1
  else
    # assign the value of each cli argument to the corresponding required arg
    local type_prefix
    local provided_arg
    local required_arg
    for ((i=0; i < "${#required_args[@]}" ; i++)); do
      required_arg="${required_args[$i]}"
      provided_arg="${provided_args[$i]}"

      # For each required arg, if it has a type prefix,
      # check that the provided type is of a type that 
      # matches the type prefix
      local re=".+:.+"
      if [[ "$required_arg" =~ $re ]]; then 
        IFS=: read -r type_prefix required_arg <<<"$required_arg"
        #type_prefix="${required_arg%%:*}"
        #required_arg="${required_arg##*:}"

        case "${type_prefix}" in
          "ra")
            if ! bg.var.is_array "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' does not exist"
              return 1 
            fi

            if ! bg.var.is_set "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' is not set"
              return 1
            fi
            ;;

          "rwa")
            if ! bg.var.is_array "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' does not exist"
              return 1 
            fi

            if ! bg.var.is_set "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' is not set"
              return 1
            fi

            if bg.var.is_readonly "$provided_arg"; then
              bg.err.print "array variable with name '$provided_arg' is read-only"
              return 1
            fi
            ;;
          *)
            bg.err.print "Type prefix '${type_prefix}' for variable '$required_arg' is not valid. Valid prefixes are: 'ra' and 'rwa'"
            return 1
            ;;
        esac
      fi

      # TODO: sanitize arguments in provided_args by replacing all double quotes(")
      # in the arg with escaped double quotes to avoid arbitrary code execution
      eval "${required_arg}=\"\${provided_arg}\""
    done
  fi

}


if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
  source arr.bash
  source env.bash
  source tty.bash
fi

################################################################################
# LOG CONSTANTS 
################################################################################
__BG_LOG_DEFAULT_FORMAT="[%-5s][%s]: %s\n"
__BG_LOG_DEFAULT_OUT="&2"


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
  local BG_LOG_FORMAT="${BG_LOG_FORMAT:-${__BG_LOG_DEFAULT_FORMAT}}"
  local -a LOG_LEVELS=( "TRACE" "DEBUG" "INFO" "WARN" "ERROR" "FATAL" )
  local -a LOG_COLOR=( "cyan" "magenta" "green" "yellow" "red" "red" )

  if ! bg.arr.is_member 'LOG_LEVELS' "$BG_LOG_LEVEL"; then
    bg.err.print "'${BG_LOG_LEVEL}' is not a valid log level. Valid values are: 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', and 'FATAL'"
    return 1
  fi

  local -i provided_log_level_index  
  provided_log_level_index="$(bg.arr.index_of 'LOG_LEVELS' "$provided_log_level")"

  local -i env_log_level_index
  env_log_level_index="$(bg.arr.index_of 'LOG_LEVELS' "$BG_LOG_LEVEL")"

  local BG_LOG_OUT="${BG_LOG_OUT:-${__BG_LOG_DEFAULT_OUT}}"
  local log_out_without_fd_prefix="${BG_LOG_OUT#&}"

  if (( env_log_level_index <= provided_log_level_index )); then
    local formatted_log_level
    formatted_log_level="$( 
      "bg.tty.${LOG_COLOR[$provided_log_level_index]}" \
      "$provided_log_level"
      )"

    # shellcheck disable=SC2059
    if [[ "${log_out_without_fd_prefix}" != "${BG_LOG_OUT}" ]]; then
      #shellcheck disable=SC2059
      printf "${BG_LOG_FORMAT}" "$( bg.env.get_parent_script_name )" "$formatted_log_level" "$message" >&"$log_out_without_fd_prefix"
    else
      #shellcheck disable=SC2059
      printf "${BG_LOG_FORMAT}" "$( bg.env.get_parent_script_name )" "$formatted_log_level" "$message" >"${BG_LOG_OUT}"
    fi

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

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
fi

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

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source trap.bash
  source str.bash
fi

export __BG_MKTEMP="mktemp"

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
    bg.err.print "'$filename_var' is not a valid variable name"
    return 1
  fi

  local tmpfile_name
  tmpfile_name="$("$__BG_MKTEMP")" \
    || { bg.err.print "Unable to create temporary file"; return 1; }
  bg.trap.add "rm -f '$tmpfile_name'" 'EXIT' \
    || { bg.err.print "Unable to set exit trap to delete file '$tmpfile_name'"; return 1; }

  # Assign name of tmpfile to variable whose name is contained in
  # filename_var
  eval "$filename_var=$tmpfile_name"
}


if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source in.bash
fi

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
      bg.err.print \
        "$(printf \
            "Error retrieving trap for signal '%s'. Error message: '%s'" \
              "$signal_spec" \
              "$trap_list_output"
         )"
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

  if bg.var.is_set 'BG_NO_FORMAT'; then
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

if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
fi

################################################################################
# VARIABLE FUNCTIONS 
################################################################################

# Checks if an array with the given name exists in the current environment
# i.e. if a variable with the given name and the -a attribute exists
# Globals:
#   None
# Arguments:
#   Name of array to look for
# Outputs:
#   None
# Returns:
#   0 if the given name refers to an existing array variable
#   1 otherwise
bg.var.is_array() ( 
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (array_name) is required but was not provided"
    return 2
  fi
  local array_name="${1}"  
  local re="declare -a"
  local array_attributes
  array_attributes="$(declare -p "$array_name" 2>/dev/null)" \
    || return 1

  if [[ "$array_attributes" =~ $re ]]; then
    return 0
  else
    return 1
  fi
)

# description: |
#   returns 0 if the given string is a readonly variable
#   returns 1 if the variable is not readonly or is unset
# inputs:
#   stdin:
#   args:
#     1: "variable name"
# outputs:
#   stdout:
#   stderr: error message when string was not provided
#   return_code:
#     0: "when the variable is readonly"
#     1: "when the variable is not readonly or unset"
# tags:
#   - "cli parsing"
bg.var.is_readonly() ( 
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (var_name) is required but was not provided"
    return 2
  fi
  local var_name="${1}"

  local re="^declare -[a-z]*r[a-z]* "
  local var_attributes
  var_attributes="$(declare -p "$var_name" 2>/dev/null)" \
    || return 1

  if [[ "$var_attributes" =~ $re ]]; then
    return 0
  else
    return 1
  fi
)


# description: |
#   returns 0 if the given variable name refers to a declared variable 
#   returns 1 if the given variable name is not declared in the execution context 
# inputs:
#   stdin:
#   args:
#     1: "variable name"
# outputs:
#   stdout:
#   stderr: error message when string was not provided
#   return_code:
#     0: "when the variable is set"
#     1: "when the variable is not set 
# tags:
# - "utility"
bg.var.is_declared() ( 
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (var_name) is required but was not provided"
    return 2
  fi
  # shellcheck disable=SC2030
  local var_name="${1}" 
  declare -p "$var_name" 1>/dev/null 2>&1
)

# description: |
#   returns 0 if the given variable name refers to a variable that's declared and
#   has a set value (even if it's an empty string or empty array). returns 1 if 
#   the given variable name is not declared or is declared but does not have a
#   set value.
# inputs:
#   stdin:
#   args:
#     1: "variable name"
# outputs:
#   stdout:
#   stderr: error message when string was not provided
#   return_code:
#     0: "when the variable is set"
#     1: "when the variable is not set 
# tags:
# - "utility"
bg.var.is_set() ( 
  if (( ${#} < 1 )); then
    bg.err.print "argument 1 (var_name) is required but was not provided"
    return 2
  fi
  # shellcheck disable=SC2030
  local var_name="${1}" 

  if ! bg.var.is_declared "$var_name"; then
    return 1
  fi

  regex='^declare -[a-zA-Z-]+ [a-zA-Z_][a-zA-Z0-9_]*\=.+$'
  if ! [[ "$( declare -p "$var_name" )" =~ $regex ]]; then
    return 1 
  fi
)


