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
  local err_default_out="&2"
  local __BG_ERR_FORMAT="${__BG_ERR_FORMAT:-${err_default_format}}"
  local __BG_ERR_OUT="${__BG_ERR_OUT:-${err_default_out}}"
  local err_out_without_fd_prefix="${__BG_ERR_OUT#&}"
  if [[ "${err_out_without_fd_prefix}" != "${__BG_ERR_OUT}" ]]; then
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >&"$err_out_without_fd_prefix" || :
  else
    #shellcheck disable=SC2059
    printf "${__BG_ERR_FORMAT}" "${1:-}" >"$err_out_without_fd_prefix" || :
  fi
)
