# Get the directory of the current file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source dependencies 
# shellcheck source=./core.bash
PATH="$SCRIPT_DIR:$PATH" source core.bash 


cli.init() {
  printf "%s\n" 'init'
}

_cli.canonicalize_opts() {
  local -a required_args=( "input_array" "output_array" )
  if ! core.require_args "$@"; then
    return 2 
  fi

  # Check if output array is readonly
  if core.is_var_readonly "$output_array"; then
    printf \
      "ERROR: '%s' is a readonly variable\n" \
      "$output_array" \
      >&2
    return 1
  fi

  # Check if output array is a valid variable name
  if ! core.is_valid_var_name "$output_array"; then
    printf \
      "ERROR: '%s' is not a valid variable name\n" \
      "$output_array" \
      >&2
    return 1
  fi


  # Empty output array
  eval "$output_array=()"

  # Check if input array exists
  # shellcheck disable=SC2154
  if ! core.is_array "$input_array"; then
    printf \
      "ERROR: array '%s' not found in execution environment\n" \
      "$input_array" \
      >&2
    return 1
  fi
 
  # Iterate over input array 
  local -i input_array_length
  eval "input_array_length=\"\${#${input_array}[@]}\""
  local short_opt_regex="^-[[:alpha:]].+$"
  local long_opt_regex="^--[[:alnum:]]+(-[[:alnum:]]+)*[[:alnum:]]+=.+$"
  local -i i
  local token
  local opt
  local arg
  for ((i=0; i<input_array_length; i++)); do
    eval "token=\"\${${input_array}[$i]}\""

    # If token matches short_opt_regex, extract opt and arg
    if [[ "$token" =~ $short_opt_regex ]]; then
      IFS= read -n 2 -d '' opt <<<"$token"
      arg="${token#"$opt"}"
      eval "$output_array+=( \"$opt\" )"
      eval "$output_array+=( \"$arg\" )"
      continue
    fi

    # If token matches long_opt_regex, extract opt and arg
    if [[ "$token" =~ $long_opt_regex ]]; then
      IFS= read -d '=' opt <<<"$token"
      arg="${token#"$opt="}"
      eval "$output_array+=( \"$opt\" )"
      eval "$output_array+=( \"$arg\" )"
      continue
    fi

    # If token didn't match any regex, just add to output_array as is
    eval "$output_array+=( \"$token\" )"

  # Regex is composed of the following expressions:
  # ^-                matches a single dash at the beginning of the string 
  # [[:alpha:]]$      matches a single letter at the end of the string

  done
}


# description: |
#   reads an argparse spec on stdin and prints the spec to stdout
#   with a new line detailing the configuration of the new flag
#   defined through the command-line parameters
# inputs:
#   stdin: an argparse spec 
#   args:
#     1: "flag short form"
#     2: "flag long form"
#     3: "environment variable where value of flag will be stored"
#     4: "help message for flag"
# outputs:
#   stdout:
#   stderr: |
#     error message if validation of arguments fails
#   return_code:
#     0: "when new line was successfully added to spec"
#     1: "when an error ocurred"
# tags:
#   - "cli parsing"
cli.add_opt() {
  # Check number of arguments
  local -a required_args=( "short_form" "long_form" "env_var" "help_message" )
  if ! core.require_args "$@"; then
    return 2 
  fi

  # Validate arguments
  if ! [[ "$short_form" =~ ^[a-z]$ ]]; then
    echo "ERROR: short form '$short_form' should be a single lowercase letter" >&2
    return 1
  fi

  if ! core.is_valid_long_opt "--$long_form"; then
    echo "ERROR: long form '$long_form' is not a valid long option" >&2
    return 1
  fi

  if ! core.is_valid_var_name "$env_var"; then
    echo "ERROR: '$env_var' is not a valid variable name" >&2
    return 1
  fi

  if core.is_var_readonly "$env_var"; then
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
  printf '%s|%s|%s|%s|%s\n' 'opt' "$short_form" "$long_form" "$env_var" "$help_message"
}


# description: |
#   reads an argparse spec on stdin and prints the spec to stdout
#   with a new line detailing the configuration of the new option with arg 
#   defined through the command-line parameters
# inputs:
#   stdin: an argparse spec 
#   args:
#     1: "option short form"
#     2: "option long form"
#     3: "environment variable where value of the option will be stored"
#     4: "help message for option"
# outputs:
#   stdout:
#   stderr: |
#     error message if validation of arguments fails
#   return_code:
#     0: "when new line was successfully added to spec"
#     1: "when an error ocurred"
# tags:
#   - "cli parsing"
cli.add_opt_with_arg() {
  # Check number of arguments
  local -a required_args=( "short_form" "long_form" "env_var" "help_message" )
  if ! core.require_args "$@"; then
    return 2 
  fi

  # Validate arguments
  if ! [[ "$short_form" =~ ^[a-z]$ ]]; then
    echo "ERROR: short form '$short_form' should be a single lowercase letter" >&2
    return 1
  fi

  if ! core.is_valid_long_opt "--$long_form"; then
    echo "ERROR: long form '$long_form' is not a valid long option" >&2
    return 1
  fi

  if ! core.is_valid_var_name "$env_var"; then
    echo "ERROR: '$env_var' is not a valid variable name" >&2
    return 1
  fi

  if core.is_var_readonly "$env_var"; then
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
  printf '%s|%s|%s|%s|%s\n' 'opt_with_arg' "$short_form" "$long_form" "$env_var" "$help_message"
}

__cli.normalize_short_opt_token() {
  # Check number of arguments
  local -a required_args=( "token" "acc_arr" "short_opts_with_arg_arr" )
  if ! core.require_args "$@"; then
    return 2 
  fi

  # Check that acc_arr contains the name of a valid array
  if ! core.is_array "$acc_arr"; then
    printf "ERROR: '%s' is not a valid array\n" "$acc_arr" >&2
    return 1
  fi

  # Check that short_opts_with_arg_arr is the name of a valid array
  if ! core.is_array "$short_opts_with_arg_arr"; then
    printf "ERROR: '%s' is not a valid array\n" "$short_opts_with_arg_arr" >&2
    return 1
  fi

  # Remove '-' from token
  token="${token#-}"

  # Get first char from token
  local first_letter
  first_letter="${token:0:1}"

  # If token only has one letter, append first letter to accumulator array and exit
  local -i token_length="${#token}"
  if ! (( token_length > 1 )); then
    eval "$acc_arr+=( -$first_letter )"
  else
    # If token has more than one letter, check if first letter expects arg
    if core.in_array "$first_letter" "$short_opts_with_arg_arr"; then
      eval "$acc_arr+=( '-$first_letter' )"
      eval "$acc_arr+=( '${token:1}' )"
    # If first letter does not expect arg, append first letter to acc_arr and recurse
    else
      eval "$acc_arr+=( '-$first_letter' )"
      __cli.normalize_short_opt_token "-${token:1}" "$acc_arr" "$short_opts_with_arg_arr"
    fi
  fi
}

cli.parse() {
  # Store all spec lines from stdin
  # into an array called 'spec_array'
  local -a spec_array
  core.to_array 'spec_array'

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
  local -a opt_long_form
  local -a opt_short_form
  local -a opt_env_var
  local -a opt_help_message
  local -a opt_help_summary
  local -a opt_has_arg

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
        local short_form
        local long_form
        local env_var
        local help_message
        local help_summary
        IFS='|' read short_form long_form env_var help_message <<<"$line"
        opt_long_form+=( "--$long_form" )
        opt_short_form+=( "-$short_form" )
        opt_env_var+=( "$env_var" )
        opt_help_message+=( "$help_message" )
        opt_has_arg+=( "false" )
        opt_help_summary+=( "-$short_form, --$long_form" )
        ;;
        #help_summary_length="${#help_summary}" # extract

        #if [[ "${help_summary_length}" -gt "${max_help_summary_length}" ]]; then # extract
        #  max_help_summary_length="${help_summary_length}" # extract
        #fi
        #n_opts=$((n_opts+1))
      opt_with_arg)
        return 0
    esac
  done 


  ################################################################################
  # Generate cli help message
  ################################################################################
  # Get routine name to be displayed in help message
  local routine_name
  routine_name="$(core.get_parent_routine_name)"

  # Find longest help summary so we can nicely align
  # auto-generated help message
  local -i max_help_summary_length=0
  for help_summary in "${opt_help_summary[@]}"; do
    help_summary_length="${#help_summary}"
    if [[ "${help_summary_length}" -gt "${max_help_summary_length}" ]]; then
      max_help_summary_length="${help_summary_length}"
    fi
  done

  # Get number of option specs so we can iterate over them
  # when creating the help message
  n_opt_specs="${#opt_short_form[@]}"

  # Fill in help message template
  ## Emtpy IFS means no word splitting
  ## -d '' means read until end of file 
  local help_message
  IFS= read -d '' help_message << EOF || true
$routine_name

Usage: $routine_name [options]

$( for (( i=0; i<n_opt_specs; i++  ));
    do
      printf "%${max_help_summary_length}s %s\n"\
        "${opt_short_form[$i]}, ${opt_long_form[$i]}" \
        "${opt_help_message[$i]}"
    done
)
EOF

  # process options
  local -i i=1
  local -i n="${#}"
  while [[ "$i" -le "$n" ]]; do
    # check if arg is '--' and if it is,
    # stop processing options
    if [[ "${!i}" == "--" ]]; then
      break
    fi

    # check if it's a short opt
    local -i index
    if core.is_valid_short_opt "${!i}"; then
      if core.in_array "${!i}" 'opt_short_form'; then
        # Find index of option in 'opt_short_form' array
        index="$( core.index_of "${!i}" 'opt_short_form' )"
        eval -- "${opt_env_var[index]}=\"\""
      elif [[ "${!i}" == "-h" ]]; then
        # if '-h' is not declared in the spec, print help 
        # message when encountered
        echo "${help_message}" >&2 
      else
        echo "ERROR: '${!i}' is not a valid option" >&2
        return 1
      fi

    # check if it's a long opt
    elif core.is_valid_long_opt "${!i}"; then
      if core.in_array "${!i}" 'opt_long_form'; then
        # Find index of option in 'opt_long_form' array
        index="$( core.index_of "${!i}" 'opt_long_form' )"
        eval -- "${opt_env_var[index]}=\"\""
      else
        echo "ERROR: '${!i}' is not a valid option" >&2
        return 1
      fi
    else
      # argument is not a long or short option, stop processing options
      break
    fi

    # Increment counter
    (( i++ ))
  done
}

