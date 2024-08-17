#!/usr/bin/env bash

source bgrim.bash

shopt -s lastpipe

main() ( 
  bg.cli.parse "$@" < <(
    bg.cli.init \
    | bg.cli.add_opt 'f' 'flag' 'myflag' 'myhe|lp' \
  )

  if bg.is_var_set 'myflag'; then
    echo "variable 'myflag' is set"
  else
   echo "variable 'myflag' is not set"
  fi
)

main "$@"
if bg.is_var_set 'myflag'; then
  echo "variable 'myflag' is set"
else
 echo "variable 'myflag' is not set"
fi




