source in.bash
source str.bash
source var.bash
source arr.bash
source env.bash
source out.bash

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
