#!/usr/bin/env bash

source bgrim.bash

set -euo pipefail

bg.caller() {
  echo "FUNCNAME=${FUNCNAME[*]}" >/dev/tty
  required_args=( 'frame' 'out_arr' )
  if ! bg.in.require_args "$@"; then
    return 2 
  fi
  local -i frame="${1:-0}"
  local -i funcname_arr_len="${#FUNCNAME[@]}"
  if (( frame+2 >= funcname_arr_len )); then
    echo "requested frame '${frame}' but there are only frames 0-$((funcname_arr_len-3)) in the call stack" >/dev/tty
    return 1
  fi
  eval "${out_arr}+=( '${BASH_LINENO[$frame+1]}' )"
  eval "${out_arr}+=( '${FUNCNAME[$frame+2]}' )"
  eval "${out_arr}+=( '${BASH_SOURCE[$frame+2]}' )"
  #printf "%s %s %s\n" "${BASH_LINENO[$frame+1]}" "${FUNCNAME[$frame+2]}" "${BASH_SOURCE[$frame]}"
}

inner_func() {
  local -a stackframe=()
  #caller 2
  bg.caller 2 stackframe
  echo "${stackframe[@]}"
}

outer_func() {
  inner_func
}

outer_outer_func() {
  outer_func
}

outer_outer_func
