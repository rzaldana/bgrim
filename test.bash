#!/usr/bin/env bash


source bgrim.bash
source lib.bash
#set +x

die() {
  declare -g __BG_DIED_GRACEFULLY=1
  exit 1
}

print_stackframe() {
  echo -e "\tat $1 ($2:$3)" >/dev/tty
}

bg.caller() {
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

print_stacktrace() {
  local -a stackframe=()
  local -i i 
  i=${1:-0}
  while bg.caller "$i" stackframe 2>/dev/null ; do
    line_no="${stackframe[0]}"
    func_name="${stackframe[1]}"
    file_name="$( realpath "${stackframe[2]}" )"
    print_stackframe "${func_name}" "${file_name}" "${line_no}"
    (( ++i ))
  done
  #coproc parsing {
  #  while read -r line_no func_name file_name; do
  #    file_name="$( realpath "$file_name" )"
  #    print_stackframe "$func_name" "$file_name" "$line_no"
  #  done
  #}

  #{
  #  local i=${1:-0}
  #  while caller "$i"; do 
  #    (( ++i ))
  #  done 
  #} >&"${parsing[1]}"
  #
  #fd="${parsing[1]}"
  #exec {fd}>&-
  #fd="${parsing[0]}"
  #exec {fd}<&-

  #wait "${parsing_PID}"
}

# die without printing stacktrace
die() {
  declare -g __BG_DIED_GRACEFULLY=1
  exit 1
}

unhandled_error() {
  trap - DEBUG
  local header
  header="__BG_BASH_COMMAND='${BASH_COMMAND}'"
  local -a captured_stderr=()
  # Drop first 3 stderr messages
  local i=0
  while (( i < 3 )); do 
    kill -s SIGUSR1 "${capture_stdout_PID}"
    IFS=: read -ru "${capture_stdout[0]}" dud_msg 
    echo "dropping msg: $dud_msg" >/dev/tty
    (( i++ )) || :
  done

  # Read messages from stderr until we find header
  local stderr_msg=""
  while [[ "$stderr_msg" != "$header" ]]; do
    captured_stderr+=( "$stderr_msg" )
    kill -s SIGUSR1 "${capture_stdout_PID}"
    read -ru "${capture_stdout[0]}" stderr_msg 
  done

  if ! bg.var.is_set '__BG_UNHANDLED_ERROR'; then
    echo "UNHANDLED ERROR:"
    local arr_leng
    arr_len="$( bg.arr.length 'captured_stderr' )"
    local -i i=$(( arr_len - 1 ))
    while (( i > 0 )); do 
      echo "${captured_stderr[$i]}"
      (( i-- )) || :
    done
    #for msg in "${captured_stderr[@]}"; do
    #  echo "${msg}"
    #done
    #printf "UNHANDLED ERROR: '%s'\n" "$mymessage"
    print_stacktrace 1 
  fi
  declare -g __BG_UNHANDLED_ERROR=1
  exit 1
}

unhandled_error2() {
  if [[ "$?" == 0 ]]; then
    exit 0
  fi
  trap - DEBUG
  if bg.var.is_set __BG_DIED_GRACEFULLY; then
    exit 1
  fi

  # Drop first 4 stderr messages
  local i=0
  while (( i < 4 )); do 
    kill -s SIGUSR1 "${capture_stdout_PID}"
    IFS=: read -ru "${capture_stdout[0]}" dud_msg 
    (( i++ )) || :
  done
  # Read next message from stderr
  kill -s SIGUSR1 "${capture_stdout_PID}"
  IFS=: read -ru "${capture_stdout[0]}" _  line_no message
  echo "message: $message" >/dev/tty
  echo "line_no: $line_no" >/dev/tty
  #lib.bash: line 5: hello: unbound variable
  # parse stderr message
  local -a stackframe=()
  local funcname
  local filename
  bg.caller 0 stackframe
  funcname="${stackframe[1]}"
  filename="$( realpath "${stackframe[2]}" )"
  if ! bg.var.is_set '__BG_UNHANDLED_ERROR'; then
    printf "UNHANDLED ERROR: '%s'\n" "${message## }"
    print_stackframe "$funcname" "$filename" "${line_no# line }"
    print_stacktrace 2 
  fi
  declare -g __BG_UNHANDLED_ERROR=1
  exit 1
}

declare -ga __BG_STDOUT_CAPTURE
coproc capture_stdout {
  trap - DEBUG
  declare -a myarray=()
  declare -i stdout_len
  declare -i index
  declare first_time=1
  trap '{ 
    # if this is the first time the trap
    # gets called, drop last three elements
    # of array
    #if [[ "$first_time" == "1" ]]; then
    #  for msg in "${myarray[@]}"; do
    #    echo "stderr: ${msg}" >/dev/tty
    #  done
    #  echo "unsetting ${myarray[-1]}" >/dev/tty
    #  unset myarray[-1];
    #  echo "unsetting ${myarray[-1]}" >/dev/tty
    #  unset myarray[-1];
    #  echo "unsetting ${myarray[-1]}" >/dev/tty
    #  unset myarray[-1];
    #  first_time=0;
    #fi
    stdout_len="$( bg.arr.length myarray )"; 
    index=$(( stdout_len - 1));
    if (( stdout_len > 0 )); then
      echo "${myarray[-1]}";
      unset "myarray[-1]";
    else
      exit 0
    fi
  }' SIGUSR1
  bg.arr.from_stdin 'myarray'
}

enrich_stderr() {
  #echo "${FUNCNAME[1]} ${BASH_SOURCE[1]} ${BASH_LINENO[0]} __BG_BASH_COMMAND='${BASH_COMMAND}'" >&2
  echo "__BG_BASH_COMMAND='${BASH_COMMAND}'" >&2
}


set -eTEuo pipefail
exec 2>&"${capture_stdout[1]}"

bg.trap.add 'unhandled_error' ERR 
bg.trap.add 'unhandled_error2' EXIT 
bg.trap.add 'enrich_stderr' DEBUG

#echo "$hello"
#myfunc

myfunc
echo "hello my name is Raul"
