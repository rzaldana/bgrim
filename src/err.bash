################################################################################
# ERROR HANDLING CONSTANTS 
################################################################################
__BG_ERR_OUT="&2"
__BG_ERR_FORMAT='ERROR: %s\n'

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
  local err_out_without_fd_prefix="${__BG_ERR_OUT#&}"
  if [[ "${err_out_without_fd_prefix}" != "${__BG_ERR_OUT}" ]]; then
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >&"$err_out_without_fd_prefix" || :
  else
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >"$err_out_without_fd_prefix" || :
  fi
)

__bg.err.get_stackframe() {
  local frame
  frame="$1"
  local out_arr
  out_arr="$2"

  # empty out arr
  eval "$out_arr=()"

  local -i funcname_arr_len="${#FUNCNAME[@]}"
  if (( frame+2 >= funcname_arr_len )); then
    bg.err.print "requested frame '${frame}' but there are only frames 0-$((funcname_arr_len-3)) in the call stack"
    return 1
  fi
  local line_no_index=$(( frame + 1 ))
  local funcname_index=$(( frame + 2 ))
  local bash_source_index=$(( frame + 2 ))
  eval "${out_arr}+=( '${BASH_LINENO[line_no_index]}' )"
  eval "${out_arr}+=( '${FUNCNAME[funcname_index]}' )"
  eval "${out_arr}+=( '${BASH_SOURCE[bash_source_index]}' )"
}
