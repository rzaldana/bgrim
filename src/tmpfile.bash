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

