#!/bin/bash
#
# This is a (simple) bash script model
# See the bottom of the file for a documentation.
#
# Author: me[at]picas[dot]fr
# License: UNLICENSE (see the bottom of the file for more info)
#
set -e
set -o errtrace

#######################################################################
## defaults
VERBOSE=0
DRYRUN=false
DEVDEBUG=false
SCRIPT_STATUS=0

## script infos
SCRIPT_VERSION="0.0.1-dev"
SCRIPT_NAME="$(basename $0)"
# a short presentation about the purpose of the script
SCRIPT_PRESENTATION="This script is a bash script model."
# an information displayed with the version number: authoring, licensing etc
SCRIPT_LICENSE=$(cat <<EOT
  Authored by Picas (contact <me[at]picas[dot]fr>)
  Released under the UNLICENSE (see <http://unlicense.org/>)
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
        -x|--debug          # enable debug mode

Options MUST be written BEFORE parameters and are treated in command line order.
Options arguments MUST be written after an equal sign: '--option=argument'.
Options MUST NOT be grouped: '-v -x'.
EOT
);
export SCRIPT_VERSION SCRIPT_LICENSE SCRIPT_NAME SCRIPT_PRESENTATION SCRIPT_USAGE_SHORT SCRIPT_USAGE

#######################################################################
## library (list of fcts to call after)

# get_help () : display help string
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

# get_version () : display version string
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

# get_manual () : display documentation (see the bottom of the script)
get_manual() {
    local line=${BASH_LINENO[0]}
    line=$((line+1))
    cat <<EOT
${SCRIPT_NAME} - v. ${SCRIPT_VERSION}
${SCRIPT_LICENSE}

EOT
    cat $0 | sed "1,${line}d;${line},/#@#/d;/#@#/,\$d" ;
    exit 0
}
export -f get_manual

# throw_error ( str='' ) : user error manager
throw_error () {
    local status=$?
    SCRIPT_STATUS=$((SCRIPT_STATUS + 1))
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
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

# dev_error ( str='' ) : development error manager
dev_error () {
    local status=$?
    [ $SCRIPT_STATUS -eq 0 ] \
        && SCRIPT_STATUS=127 \
        || SCRIPT_STATUS=$((SCRIPT_STATUS + 1)) \
    ;
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
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

# get_backtrace () : print a stack trace of current run
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

# verbose_echo ( str ) : echo info if VERBOSE enabled
verbose_echo () {
    [ $# -eq 0 ] && dev_error_missing_argument "usage: ${FUNCNAME[0]} <str>";
    [ $VERBOSE -gt 0 ] && echo "[INFO] > $*" || return 0;
}
export -f verbose_echo
export VERBOSE

# get_absolute_path ( path ) : get a 'real' path
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

# debug () : environment vars debugging
debug() {
    cat <<EOT
[DEBUG]
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
## the actual script

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
        -x|--debug) DEVDEBUG=true ;;
        --manual) get_manual ;;
        --dry-run|--check) DRYRUN=true ;;
        -*) throw_error "unknown option '$1'" ;;
        *) break ;;
    esac
    shift
done
export VERBOSE DRYRUN DEVDEBUG SCRIPT_STATUS

## let's go for scripting! ;)

# param1="$1"
# ...

# uncomment one of these lines to test a feature:
# throw_error 'test error...'
# dev_error 'test dev error...'
# cmd_not_found
# verbose_echo 'test verbosity...'

echo 'yo'

$DEVDEBUG && debug;
echo '-- end of script'
exit 0

## script end - anything below is documentation and not executed
#@#
# LICENSE
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>
#@#
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=sh