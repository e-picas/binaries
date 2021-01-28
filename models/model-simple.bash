#!/bin/bash
#
# This is a (simple) Bash script model
# 
# Some '[man]' strings are present in the comments to identify #@!
# what to do to turn this template to your own script.
# See the bottom of the file for a longer documentation.
# Released into the public domain (see the bottom of the file for more info)
# by Picas <me[at]picas.fr>
#
set -e
set -o errtrace

#######################################################################
## [man] Default flags
VERBOSE=0
DRYRUN=false
DEVDEBUG=false
SCRIPT_STATUS=0
SCRIPT_NAME="$(basename $0)"
LOGFILE="$0.log"

## [man] Script infos
# the version number - you must increase it and follow the semantic versioning standards <https://semver.org/>
SCRIPT_VERSION="0.0.1-dev"
# a short presentation about the purpose of the script
SCRIPT_PRESENTATION=$(cat <<EOT
This software is a (simple) Bash script model (see <https://tldp.org/LDP/abs/html/>).
You can use it as a template or an help for your own scripts.
You may work on the source code to see how to use it...
EOT
);
# an information displayed with the version number: authoring, licensing etc
SCRIPT_LICENSE=$(cat <<EOT
  Authored by Picas (<me[at]picas.fr>)
  Released UNLICENSEd into the public domain
EOT
);
# a quick usage string, complete but concise
SCRIPT_USAGE_SHORT=$(cat <<EOT
usage:  $SCRIPT_NAME [-v|-x] [--option[=arg]] <parameters>
        $SCRIPT_NAME -h | --help
EOT
);
# the long helping string explaining how to use the script
SCRIPT_USAGE=$(cat <<EOT
$SCRIPT_USAGE_SHORT

options:
        --option[=arg]      # to do what ?
        -v|--verbose        # increase verbosity
        -q|--quiet          # decrease verbosity
        --dry-run|--check   # enable "dry-run" mode (nothing is actually done)

special options:
        -h|--help           # display help string
        -V|--version        # display version string

Options MUST be written BEFORE parameters and are treated in command line order.
Options arguments MUST be written after an equal sign: '--option=argument'.
Options MUST NOT be grouped: '-v -x'.
EOT
);
export SCRIPT_VERSION SCRIPT_LICENSE SCRIPT_NAME SCRIPT_PRESENTATION SCRIPT_USAGE_SHORT SCRIPT_USAGE

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
    if $DEVDEBUG
    then
        local manlines=$(grep -n '\[man\]' $0 | grep -v '#@!');
        cat >&2 <<EOT
[DEV] > MANUAL
---
script path: $0

manual extract (matching '[man]' / excluding '#@!') with line number:

$manlines

---
[${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
    else
        cat $0 | sed "1,${BASH_LINENO[0]}d;${BASH_LINENO[0]},/#@#/d;/#@#/,\$d" | sed -e 's/^#//' ;
    fi
    exit 0
}
export -f get_manual

## [man][fct] write_log ( <type> <message> ) : add a line to the logs
write_log() {
    [ $# -lt 2 ] && dev_error_missing_argument "usage: ${FUNCNAME[0]} <type> <message>";
    local type="$1"
    shift
    local msg="$*"
    echo "$(date +'%Y-%m-%d:%H:%M %s') | [$type] $msg" >> $LOGFILE ;
}
export -f write_log
export LOGFILE

## [man][fct] throw_error ( str='' ) : user error manager
throw_error () {
    local status=$?
    SCRIPT_STATUS=$((SCRIPT_STATUS + 1))
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    write_log error "$* - exit status $SCRIPT_STATUS";
    cat >&2 <<EOT
[ERROR] > $*
---
${SCRIPT_USAGE_SHORT}
---
[${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
    exit $SCRIPT_STATUS
}
export -f throw_error
export SCRIPT_STATUS

## [man][fct] dev_error ( str='' ) : development error manager
dev_error () {
    local status=$?
    [ $SCRIPT_STATUS -eq 0 ] \
        && SCRIPT_STATUS=127 \
        || SCRIPT_STATUS=$((SCRIPT_STATUS + 1)) \
    ;
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    write_log dev_error "$* - exit status $SCRIPT_STATUS";
    cat >&2 <<EOT
[DEV ERROR] > $*
---
exit status: $SCRIPT_STATUS

stack backtrace:
$(get_backtrace)

---
[${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
    exit $SCRIPT_STATUS
}
export -f dev_error
export SCRIPT_STATUS

# trap a signal and throw it to 'dev_error ()'
# trapped signals:
#   errors (ERR)
#   script exit (EXIT)
#   interrupt (SIGINT)
#   terminate (SIGTERM)
#   kill (KILL)
trap 'dev_error $?' ERR

## [man][fct] get_backtrace () : print a stack trace of current run
# https://stackoverflow.com/questions/25492953/bash-how-to-get-the-call-chain-on-errors
get_backtrace () {
    local deptn=${#FUNCNAME[@]}
    for ((i=1; i<$deptn; i++)); do
        local func="${FUNCNAME[$i]}"
        local line="${BASH_LINENO[$((i-1))]}"
        local src="${BASH_SOURCE[$((i-1))]}"
        printf '%*s' $i '' # indent
        echo "at: $func(), $src, line $line"
    done
}
export -f get_backtrace

# dev_error aliases
dev_error_missing_argument() { dev_error "missing argument > $*"; }
export -f dev_error_missing_argument

## [man][fct] verbose_echo ( str ) : echo info if VERBOSE enabled
verbose_echo () {
    [ $# -eq 0 ] && dev_error_missing_argument "usage: ${FUNCNAME[0]} <str>";
    [ $VERBOSE -gt 0 ] && echo "[INFO] > $*" || return 0;
}
export -f verbose_echo
export VERBOSE

## [man][fct] get_absolute_path ( path ) : get a 'real' path
get_absolute_path() {
    [ $# -eq 0 ] && dev_error_missing_argument "usage: ${FUNCNAME[0]} <path>";
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

#######################################################################
## [man] Arguments, parameters & options

# if arguments are required
[ $# -eq 0 ] && throw_error 'arguments are required';

# arguments
while [ $# -gt 0 ]; do
    ARG_PARAM="$(cut -d'=' -f2 <<< "$1")"
    case "$1" in
        # user options...
        --option=*) VAR="$ARG_PARAM" ;;
        # you should NOT change below
        -h|--help) get_help ;;
        -V|--version) get_version ;;
        -v|--verbose) VERBOSE=$((VERBOSE + 1)) ;;
        -q|--quiet) VERBOSE=$((VERBOSE - 1)) ;;
        --dry-run|--check) DRYRUN=true ;;
        # for development...
        -x|--debug) DEVDEBUG=true ;;
        --manual) get_manual ;;
        -*) throw_error "unknown option '$1'" ;;
        *) break ;;
    esac
    shift
done
export VERBOSE DRYRUN DEVDEBUG SCRIPT_STATUS

#######################################################################
## [man] Let's go for scripting ;)



$DEVDEBUG && debug;
echo '-- end of script'
exit 0

#######################################################################
## [man] Script ends here - anything below is documentation and not executed #@!
#@#
# Simple Bash Model
# ====
# Sources: <https://github.com/e-picas/binaries/blob/master/models/model-simple.bash>
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
#       throw_error 'test error...'
#       
#       # throws a development error with a stack trace
#       dev_error 'test dev error...'
#       
#       # test error trapping
#       cmd_not_found
#       
#       # this will only write 'test verbosity...' if the '--verbose' option is used
#       verbose_echo 'test verbosity...'
#       
#       # write a string to the logs
#       write_log info 'test log'
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
#@#
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=sh
