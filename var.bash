source err.bash

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

