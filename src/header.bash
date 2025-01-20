#!/usr/bin/env bash 

# Copyright (c) 2024 Raul Armando Zaldana Calles
# Source: https://github.com/rzaldana/bgrim

################################################################################
##############       ######      ###       #####  ###         ##################
#############         ####       ##         ###   ##           #################
#############   ###    ##    ######   ###    ##   ##   #   #   #################
#############   ####   ##   #######   ####   ##   ##   #####   #################
#############   #      ##   #######   ####   ##   ##   #####   #################
#############   ##    ###   #######   ###    ##   ##   #####   #################
#############   ####   ##   #######         ###   ##   #####   #################
#############   ####   ##   #    ##         ###   ##   #####   #################
#############   ####   ##   #    ##   ###    ##   ##   #####   #################
#############   ####   ##   ###  ##   ####   ##   ##   #####   #################
#############   #     ####       ##   ####   ##   ##   #####   #################
#############   ##   ######      ##   ####   ##   ##   #####   #################
#############  ####################  ##########  ###########  ##################
############# ##################### ########### ############ ###################
################################################################################

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Check that we're running bash 
# This part needs to be POSIX shell compliant
# shellcheck disable=SC2128
if [ -z "${BASH_VERSINFO}" ]; then
  echo "[$0][ERROR]: This script is only compatible with Bash and cannot be run in other shells"
  exit 1
fi

# Check that we're running a supported version of bash
readonly -a __bg_min_bash_version=( '4' '4' '23' )
for vers_index in "${!BASH_VERSINFO[@]}"; do
  subversion="${BASH_VERSINFO[$vers_index]}"
  if (( subversion < __bg_min_bash_version[vers_index] )); then
    printf "[$0][ERROR]: This script is only compatible with Bash versions higher than %s.%s.%s but it's being run in bash version ${BASH_VERSION}\n" \
      "${__bg_min_bash_version[0]}" \
      "${__bg_min_bash_version[1]}" \
      "${__bg_min_bash_version[2]}"
    exit 1
  else
    break
  fi
done

################################################################################
# GLOBAL CONSTANTS
################################################################################
