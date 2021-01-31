#!/bin/bash
#
# A Simple Bash Library
# Sources: <https://github.com/e-picas/binaries/blob/master/library-picas.bash>
# Author: Picas (<me[at]picas.fr>) - 2021
# 
# This is a (simple) library for Bash scripting
# See the bottom of the file for a longer documentation.
# Released into the public domain (see the bottom of the file for more info)
# by Picas <me[at]picas.fr>
#
set -e
set -o errtrace

#######################################################################
## [man] Default flags refixed by LB_ for 'Library Bash'_
export VERBOSE=0
export DRYRUN=false
export DEVDEBUG=false
export LOGGING=false
export LOGFILE="$BASH_SOURCE.log"
export SCRIPT_STATUS=0

## [man] Script infos
# the path of the library
export LB_SCRIPT_PATH="$BASH_SOURCE"
# the filename of that path
export LB_SCRIPT_NAME="$(basename $BASH_SOURCE)"
# the version number - you must increase it and follow the semantic versioning standards <https://semver.org/>
export LB_SCRIPT_VERSION="0.0.1-dev"
# a short presentation about the purpose of the script
export LB_SCRIPT_PRESENTATION=$(cat <<EOT
This software is a (simple) library for Bash scripting (see <https://tldp.org/LDP/abs/html/>).
You can use it as a library of functions to help you for your own scripts.
EOT
);
# an information displayed with the version number: authoring, licensing etc
export LB_SCRIPT_LICENSE=$(cat <<EOT
  Authored by Picas (<me[at]picas.fr>)
  Released UNLICENSEd into the public domain
EOT
);
# a quick usage string, complete but concise
export LB_SCRIPT_USAGE_SHORT=$(cat <<EOT
usage:  $SCRIPT_NAME [-v|-x] [--option[=arg]] <parameters>
        $SCRIPT_NAME -h | --help
EOT
);
# the long helping string explaining how to use the script
export LB_SCRIPT_USAGE=$(cat <<EOT
$LB_SCRIPT_USAGE_SHORT

options:
        --option[=arg]      : to do what ?
        -v|--verbose        : increase verbosity
        -q|--quiet          : decrease verbosity
        -l|--log            : enable logging
        --dry-run|--check   : enable "dry-run" mode (nothing is actually done)

special options:
        --help              : display help string
        --version           : display version string
        --manual            : display long documentation string
        --debug             : enable debug mode

Options MUST be written BEFORE parameters and are treated in command line order.
Options arguments MUST be written after an equal sign: '--option=argument'.
Options MUST NOT be grouped: '-v -x'.
EOT
);
# export SCRIPT_VERSION
# export SCRIPT_LICENSE
# export SCRIPT_NAME
# export SCRIPT_PRESENTATION
# export SCRIPT_USAGE_SHORT
# export SCRIPT_USAGE

#######################################################################
## [man] Library of functions you can use after declaration

## [man][fct] get_help () : display help string
get_help () {
    cat <<EOT
--- [${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]

${SCRIPT_PRESENTATION}

${SCRIPT_USAGE}
---
EOT
    exit 0
}
export -f get_help

## [man][fct] get_version () : display version string
get_version () {
    if [ $VERBOSE -lt 0 ]
    then echo "${SCRIPT_VERSION}"
    else cat <<EOT
${SCRIPT_NAME} - v. ${SCRIPT_VERSION}
${SCRIPT_LICENSE}
EOT
    fi
    exit 0
}
export -f get_version


## [man][fct] get_manual () : display documentation (see the bottom of the script)
get_manual() {
    local filepath="${1:-$LB_SCRIPT_PATH}"
    if $DEVDEBUG
    then
        get_manual_developer
    else
        local linenb_end_lib_first=$(grep -n "${TAG_ENDLIB}" $filepath | grep -v 'export ' | head -n1 | cut -d: -f1)
        cat $filepath | sed "1,${linenb_end_lib_first}d;${linenb_end_lib_first},/${TAG_DOC}/d;/${TAG_DOC}/,\$d" | sed -e 's/^#//' ;
    fi
    exit 0
}
export -f get_manual
export TAG_DOC='#_doc_#'
export TAG_ENDLIB='#_end_lib_#'

## [man][fct] get_manual_developer () : display lines with a '[man]' mark
get_manual_developer() {
    local filepath="${1:-$LB_SCRIPT_PATH}"
    local manlines=$(grep -n "$TAG_MAN" $filepath | grep -v "$TAG_EXCLUDE");
    cat >&2 <<EOT
[DEV] > MANUAL
---
script path: $0

manual extract (matching '[man]' / excluding '#@!') with line number:

$manlines

existing functions:

$(typeset -F)

---
[${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT

#env | grep -v BASH_FUNC

    exit 0
}
export -f get_manual_developer
export TAG_MAN='\[man\]'
export TAG_EXCLUDE='#@!'

## [man][fct] get_options_list () : display lines with a '[man]' mark
get_options_list() {
    local linenb_end_lib_first=$(grep -n "${TAG_ENDLIB}" $0 | grep -v 'export ' | head -n1 | cut -d: -f1)
    local opts_lines=$(cat $0 | sed "1,${linenb_end_lib_first}d;${linenb_end_lib_first},/${TAG_OPTS}/d;/${TAG_OPTS}/,\$d" | sed -e 's/^#//' );
    local line_opt line_comment
    while read -r line
    do
        if [[ "$line" == '-'* ]]; then
            line_opt=$(echo "$line" | cut -d')' -f1);
            line_comment=$(echo "$line" | grep '#' | cut -d'#' -f2);
            line_opt="${line_opt//=*/=<arg>}"
            line_opt="${line_opt//|/, }"
            echo "    $line_opt    : $line_comment"
        fi
    done < <(echo "$opts_lines")
    exit 0
}
export -f get_options_list
export TAG_OPTS='#_opts_#'

## [man][fct] log_write ( <type> <message> ) : add a line to the logs
log_write() {
    $LOGGING || return 0;
    [ $# -lt 2 ] && error_dev_missing_argument "usage: ${FUNCNAME[0]} <type> <message>";
    local type="$1"
    shift
    local msg="$*"
    echo "$(date +'%Y-%m-%d:%H:%M %s') | [$type] $msg" >> $LOGFILE ;
}
export -f log_write
export LOGFILE LOGGING

## [man][fct] error_throw ( str='' ) : user error manager
error_throw () {
    local status=$?
    SCRIPT_STATUS=$((SCRIPT_STATUS + 1))
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    log_write error "$* - exit status $SCRIPT_STATUS";
    cat >&2 <<EOT
[ERROR] > $*
---
${SCRIPT_USAGE_SHORT}
---
[${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
    exit $SCRIPT_STATUS
}
export -f error_throw
export SCRIPT_STATUS

## [man][fct] error_dev_output ( str='' ) : development error manager
error_dev_output () {
    cat >&2 <<EOT
[DEV ERROR] > $*
---
exit status: $SCRIPT_STATUS

stack backtrace:
$(get_backtrace)

---
[${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
}
export -f error_dev_output

## [man][fct] error_dev ( str='' ) : development error manager
error_dev () {
    local status=$?
    [ $SCRIPT_STATUS -eq 0 ] \
        && SCRIPT_STATUS=127 \
        || SCRIPT_STATUS=$((SCRIPT_STATUS + 1)) \
    ;
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    log_write error_dev "$* - exit status $SCRIPT_STATUS";
    error_dev_output "$*"
    exit $SCRIPT_STATUS
}
export -f error_dev
export SCRIPT_STATUS

# trapped signals:
#   errors (ERR)
#   script exit (EXIT)
#   interrupt (SIGINT)
#   terminate (SIGTERM)
#   kill (KILL)

## [man][fct] error_exit ( str='' ) : user exit error manager
error_interrupt() {
    local status=$?
    [ $SCRIPT_STATUS -eq 0 ] \
        && SCRIPT_STATUS=127 \
        || SCRIPT_STATUS=$((SCRIPT_STATUS + 1)) \
    ;
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    log_write error_signal "[SIGINT] $* - exit status $SCRIPT_STATUS";
    error_dev_output "USER EXIT (SIGINT) > $*"
    exit $SCRIPT_STATUS
}
export -f error_interrupt

## [man][fct] get_backtrace () : print a stack trace of current run
# https://stackoverflow.com/questions/25492953/bash-how-to-get-the-call-chain-on-errors
get_backtrace () {
    local deptn=${#FUNCNAME[@]}
    for ((i=$deptn; i>0; i--)); do
        local func="${FUNCNAME[$i]}"
        local line="${BASH_LINENO[$((i-1))]}"
        local src="${BASH_SOURCE[$((i-1))]}"
        printf '%*s' $i '' # indent
        echo "at: $func(), $src, line $line"
    done
}
export -f get_backtrace

# error_dev aliases
error_dev_missing_argument() { error_dev "missing argument > $*"; }
export -f error_dev_missing_argument

## [man][fct] echo_verbose ( str ) : echo info if VERBOSE enabled
echo_verbose () {
    [ $# -eq 0 ] && error_dev_missing_argument "usage: ${FUNCNAME[0]} <str>";
    [ $VERBOSE -gt 0 ] && echo "[INFO] > $*" || return 0;
}
export -f echo_verbose
export VERBOSE

## [man][fct] get_absolute_path ( path ) : get a 'real' path
get_absolute_path() {
    [ $# -eq 0 ] && error_dev_missing_argument "usage: ${FUNCNAME[0]} <path>";
    local cwd="$(pwd)"
    local path="$1"
    while [ -n "$path" ]; do
        cd "${path%/*}" 2>/dev/null;
        local name="${path##*/}"
        path="$($(type -p greadlink readlink | head -1) "$name" || true)"
    done
    pwd
    cd "$cwd"
}
export -f get_absolute_path

## [man][fct] debug () : environment vars debugging
debug() {
    cat <<EOT
[DEV] > DEBUG
---
> process ID $$
> printed on $(date +'%Y/%m/%d %H:%M:%S %Z')

--- Script infos ---
exit status:    $SCRIPT_STATUS
verbosity:      $VERBOSE
logging:        $LOGGING
log file:       $LOGFILE
dry-run:        $DRYRUN
debug mode:     $DEVDEBUG

--- Stack backtrace ---
$(get_backtrace)

--- System infos ---
shell:          $(bash --version | head -n1)
hotname:        $(hostname)
running:        $(uname -ro)
uptime:         $(uptime -s)

---
[DEBUG - ${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
}
export -f debug

#_end_lib_#
#######################################################################
## [man] System & global settings

# trap a signal and throw it to 'error_dev ()'
# trap 'error_dev $?' ERR


## [man] Arguments, parameters & options

# # if arguments are required
# [ $# -eq 0 ] && error_throw 'arguments are required';

# arguments
treat_arguments() {
    echo "$*"
    ARGS_ORIG="$*"
    while :; do
        echo "$1"
        ARG_PARAM="$(cut -d'=' -f2 <<< "$1")"
        case "$1" in
    ## this is used to generate a list of available options
    #_opts_#
            # you should NOT change below
            -h|--help) get_help ;; # display help string
            -V|--version) get_version ;; # display version string
            -v|--verbose) VERBOSE=$((VERBOSE + 1)) ;; # increase verbosity
            -q|--quiet) VERBOSE=$((VERBOSE - 1)) ;; # decrease verbosity
            --dry-run|--check) DRYRUN=true ;; # enable "dry-run" mode (nothing is actually done)
            # for development...
            --manual) get_manual ;; # display manual
            --options) get_options_list ;; # display options list
            -x|--debug) DEVDEBUG=true ;; # enable debug mode
            -l|--log) LOGGING=true ;; # enable logging
            --log-file=*) LOGFILE="$ARG_PARAM" ;; # set logfile path
    #_opts_#
            *) break ;;
        esac
        shift
    done
    export VERBOSE DRYRUN DEVDEBUG SCRIPT_STATUS LOGGING LOGFILE
    echo "$*"
    set - $ARGS_ORIG
    echo "$*"
    echo 'yo'; exit 2;
}
treat_arguments "$*"

#######################################################################
## [man] Script ends here - anything below is documentation and not executed #@!
#_doc_#
# A Simple Bash Library
# ====
# Sources: <https://github.com/e-picas/binaries/blob/master/library-picas.bash>
# Author: Picas (<me[at]picas.fr>) - 2021
# 
# ## USAGE
# 
# As usual when coding, the source code itself may represent the base documentation.
# Functions, variables and constants may be easy to understand and you should
# apply these rules when coding yourself.
#
# If you have any interrogation about Bash, you may refer to the "Bash scripting guide"
# available online at <https://tldp.org/LDP/abs/html/>.
#
# ### Create your copy
# 
# To get a copy of the template, you can download it running
# 
#       wget -O my-script.sh https://raw.githubusercontent.com/e-picas/binaries/master/models/model-simple.bash
#       vi my-script.sh
#       # ...
#       bash my-script.sh
# 
# ### Template features
# 
# This script intend to be a kind of framework to work with
# when writing Bash scripts. It is ready to:
# 
# -     handle errors printing the error message with some more informations
#       (a specific handler is available for development usage)
# -     handle common options, i.e. '--help' or '--verbose', and 
#       let you add your own options
# -     build some information strings about the script, i.e. when using 
#       '--help' or '--version' options
# -     manage a logfile to write some traces in
# 
# ### How to use this template
# 
# First of all you may (re)define the `SCRIPT_...` variables with your informations. 
# 
# In the scripting zone, user parameters without a leading dash are available,
# you can use them like: `param1="$1"`
# 
# You can test a feature with one of the followings:
# 
#       # throws a classic 'usage' error
#       error_throw 'test error...'
#       
#       # throws a development error with a stack trace
#       error_dev 'test dev error...'
#       
#       # test error trapping
#       cmd_not_found
#       
#       # this will only write 'test verbosity...' if the '--verbose' option is used
#       echo_verbose 'test verbosity...'
#       
#       # write a string to the logs
#       log_write info 'test log'
# 
# ### Development tricks
# 
# To exit for debugging and keep information of where you are, you can use:
# 
#       # <nb of args> <all args themselves> at <file name>:<current line nb>
#       echo "$# $* at ${BASH_SOURCE}:${LINENO}"
#       exit 0
# 
# ## (un)LICENSE
#
# This program is free software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# I dedicate any and all copyright interest in this software to the
# public domain. I make this dedication for the benefit of the public at
# large and to the detriment of my heirs and successors. I intend this
# dedication to be an overt act of relinquishment in perpetuity of all
# present and future rights to this software under copyright law.
#
# I disclaim all warranties with regard to this software.
#
# For more information, please refer to <http://unlicense.org/>
#_doc_#
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=sh
