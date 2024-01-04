#!/usr/bin/env bash

################################################################################
# Description: |
#   prints all continuous lines above a function definition that start with a 
#   hash (#)
# Globals: null
# Arguments:
#   1: source file where function is defined
#   2: name of function
# Outputs:
#   stdout: the comment above the function with the hash (#) removed
# Returns:
#   0: if the function is found and the comment successfully extracted
################################################################################
print_function_comment() {
  local source_file="${1:-}"
  local function_name="${2:-}"

  [[ -z "$source_file" ]] && { echo "arg1 [source_file] is empty" >&2; return 1; }
  [[ -z "$function_name" ]] && { echo "arg2 [function_name] is empty" >&2; return 1; }


  local sed_script
  sed_script="$(cat <<EOF
  /##*#/ {
    # when a line matches the /##*#/ pattern,
    # replace the contents of the hold space with 
    # the pattern space and then place the overwrite
    # the pattern space with the next line of input
    h; n 
    :start
    # If the next line starts with a hash sign,
    # Run the commands in between the braces ({})
    # until the first line that does not start with a hash
    /^#+/{
      # append the contents of the pattern space to hold space
      # and replace the pattern space with the next line of input
      H; n
      # go back to the :start label and continue execution from there
      b start
    }

    # when we reach the first line that does not start with a hash,
    # execute the following commands if the function definition
    # is found in that line
    /$function_name\(\)/{
      # Copy the contents from the hold space to the pattern space
      # and print the pattern space
      g; p 
    }
  }
EOF
)"

  sed -nE "$sed_script" <"$source_file" || echo "ERROR"
}

remove_comment_separators() {
  # Remove any line made up of all hash signs
  local sed_script
  sed_script="$(cat <<EOF
  /##*#/ !{
    p
  }
EOF
)"
  sed -nE "$sed_script" </dev/stdin || echo "ERROR"
}


remove_hashes() {
  # Remove first hash sign from every input line
  local sed_script
  sed_script='s/^#\{1,\}[[:blank:]]\{0,1\}//'
  sed "$sed_script" </dev/stdin || echo "ERROR"
}

print_function_declaration_lines() {
  sed -n '/[[:alnum:]:_]\{1,\}()/p'
}

remove_leading_spaces() {
  sed 's/^[[:space:]]\{1,\}//'
}

remove_trailing_spaces() {
  sed 's/[[:space:]]$//'
}

remove_curly_braces() {
  sed 's/[{}]\{1\}//'
}

remove_parentheses() {
  sed 's/()$//'
}

print_functions_in_file() {
  local filename="${1:-}"
 
  print_function_declaration_lines <"$filename" \
    | remove_leading_spaces \
    | remove_curly_braces \
    | remove_trailing_spaces \
    | remove_parentheses
}

is_yaml() {
  yq >/dev/null 2>&1 && return 0
  return 1
}

is_function_comment_yaml() {
  local filename="${1:-}"
  local function_name="${2:-}"
  set -o pipefail
  print_function_comment "$filename" "$function_name" \
    | remove_comment_separators \
    | remove_hashes \
    | is_yaml \
    && return 0
  return 1
}

main() {
  local filename="${1:-}"
  print_functions_in_file "$filename" | \
    while read -r function_name; do
      if is_function_comment_yaml "$filename" "$function_name"; then \
        printf '%s\t\tYES\n' "$function_name"
      else
        printf '%s\t\tNO\n' "$function_name"
      fi
    done
}

main "$@"
