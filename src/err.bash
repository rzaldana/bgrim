################################################################################
# ERROR HANDLING CONSTANTS 
################################################################################
__BG_ERR_FORMAT='ERROR: %s\n'

################################################################################
# ERROR HANDLING FUNCTIONS 
################################################################################
# description: Prints a formatted error messag to stdoute
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
  #shellcheck disable=SC2059
  printf "${__BG_ERR_FORMAT}" "${1:-}" >&2 || :
)

