if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
  source var.bash
  source str.bash
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
          *)
            bg.err.print "Type prefix '${type_prefix}' for variable '$required_arg' is not valid. Valid prefixes are: 'ra', 'rwa', and 'int'"
            return 1
            ;;
        esac
      fi

      # sanitize arguments in provided_args by replacing all single quotes(')
      # in the arg with escaped single quotes to avoid arbitrary code execution
      eval "${required_arg}='$( bg.str.escape_single_quotes "${provided_arg}" )'"
    done
  fi

}

