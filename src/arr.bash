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
