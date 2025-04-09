if [[ -n "${__BG_TEST_MODE:-}" ]]; then
  source err.bash
fi

################################################################################
# Functions for formatting text 
################################################################################
bg.fmt.title() {
  local message="${1:-}"
  local -i max_width="80"
  local title_char="="


  local -i message_length
  local -i left_padding
  local -i right_padding

  message_length="${#message}"

  # Add spaces around message if it will not surpass max width
  # and if it is not an empty string
  if (( (message_length + 2) <= max_width )) && (( message_length != 0 )); then
    message=" ${message} "
    message_length="${#message}"
  fi

  total_padding="$(( max_width - message_length ))" 
  left_padding="$(( total_padding / 2 ))"
  right_padding="$left_padding"

  # If total padding is odd, increase right padding by 1 
  (( (total_padding % 2) == 1 )) && left_padding="$(( left_padding + 1 ))"

  ## Print left padding
  for ((i=0;i<left_padding;i++)); do
    printf '%s' "$title_char"
  done

  ## Print message
  printf '%s' "$message"

  ## Printf right_padding
  for ((i=0;i<right_padding;i++)); do
    printf '%s' "$title_char"
  done

  ## Print newline
  printf '\n'
}
