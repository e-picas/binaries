#!/bin/bash
#
# A Simple Bash Library
# Sources: <https://github.com/e-picas/binaries/blob/master/library-picas.bash>
# Author: Picas (<me[at]picas.fr>) - 2021
# 
# This is a (simple) library for Bash scripting
# See the bottom of the file for a longer documentation
# Released into the public domain (see the bottom of the file for more info)
# By Picas <me[at]picas.fr>
#

#######################################################################
## [man] Bash options
# abort script at first command with a non-zero status (set -e)
set -o errexit
# trap on ERR are inherited by shell functions (set -E)
set -o errtrace
# do not mask pipeline's errors
set -o pipefail
# trap on DEBUG and RETURN are inherited by shell functions (set -T)
set -o functrace
# throw error on unset variable usage (set -u)
set -o nounset
# export all defined variables (set -a)
# set -o allexport

#######################################################################
## [man] Default flags you can overwrite in your child script
export VERBOSE=0
export DRYRUN=false
export DEVDEBUG=false
export LOGGING=false
export LOGFILE="$BASH_SOURCE.log"

## [man] Default flags to NOT overwrite
export SCRIPT_STATUS=0
export LIB_DIRECT=false
readonly CMD_ARGS="$*"

## [man] Library infos prefixed by LIB_
# the path of the library
readonly LIB_SCRIPT_PATH="$BASH_SOURCE"
# the filename of that path
readonly LIB_SCRIPT_NAME="$(basename $BASH_SOURCE)"
# the version number - you must increase it and follow the semantic versioning standards <https://semver.org/>
readonly LIB_SCRIPT_VERSION="0.0.1-dev"
# a short presentation about the purpose of the script
readonly LIB_SCRIPT_PRESENTATION=$(cat <<EOT
This software is a (simple) library for Bash scripting (see <https://tldp.org/LDP/abs/html/>).
You can use it as a library of functions to help you for your own scripts.
EOT
);
# an information displayed with the version number: authoring, licensing etc
readonly LIB_SCRIPT_LICENSE=$(cat <<EOT
  Authored by Picas (<me[at]picas.fr>)
  Released UNLICENSEd into the public domain
EOT
);
# a quick usage string, complete but concise
readonly LIB_SCRIPT_USAGE_SHORT=$(cat <<EOT
usage:  $0 [-v|-x] [--option[=arg]] <parameters>
        $0 --help
EOT
);
# an information about how to write script options & arguments
readonly LIB_OPTIONS_USAGE=$(cat <<EOT
Options MUST be written BEFORE parameters and are treated in command line order.
Options arguments MUST be written after an equal sign: '--option=argument'.
Options MUST NOT be grouped: '-v -x'.
EOT
);
# the long helping string explaining how to use the script
readonly LIB_SCRIPT_USAGE=$(cat <<EOT
$LIB_SCRIPT_USAGE_SHORT

options:
%_options_list_%

${LIB_OPTIONS_USAGE}
EOT
);
export SCRIPT_PATH="$0"
export SCRIPT_NAME="$(basename $0)"
export SCRIPT_VERSION
export SCRIPT_LICENSE
export SCRIPT_PRESENTATION
export SCRIPT_USAGE_SHORT
export SCRIPT_USAGE

#######################################################################
## [man] Library of functions for output script's information

## [man][fct] get_signature () : display name & version
get_signature () {
    $LIB_DIRECT \
        && echo "${LIB_SCRIPT_NAME} - v. ${LIB_SCRIPT_VERSION}" \
        || echo "${SCRIPT_NAME} - v. ${SCRIPT_VERSION}" \
    ;
}
export -f get_signature

## [man][fct] get_usage () : display usage string
get_usage () {
    cat <<EOT
${SCRIPT_USAGE_SHORT}
EOT
}
export -f get_usage

## [man][fct] get_help () : display help string
get_help () {
    local opts_list="$(get_options_list)"
    # escape the string for sed - see <https://unix.stackexchange.com/a/60322>
    opts_list="$(printf '%s\n' "$opts_list" | sed 's,[\/&],\\&,g;s/$/\\/')"
    opts_list="${opts_list%?}"
    cat <<EOT | sed -e "s/${MASK_OPTIONS_LIST}/${opts_list}/g"
--- [$(get_signature)]

${SCRIPT_PRESENTATION}

${SCRIPT_USAGE}
---
EOT
    exit 0
}
export -f get_help
export MASK_OPTIONS_LIST='%_options_list_%'

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
get_manual () {
    local filepath="${1:-$0}"
    local linenb_doc_first=$(grep -n "${TAG_DOC}" $filepath | grep -v 'export ' | head -n1 | cut -d: -f1)
    cat $filepath | sed "1,${linenb_doc_first}d;/${TAG_DOC}/,\$d" | sed -e 's/^#//' ;
    exit 0
}
export -f get_manual
export TAG_DOC='#_doc_#'

#######################################################################
## [man] Library of functions for output script's information for development

## [man][fct] get_manual_developer () : display lines with a '[man]' mark
get_manual_developer() {
    local filepath="${1:-$0}"
    local manlines=$(grep -n "$TAG_MAN" $filepath | grep -v "$TAG_EXCLUDE");
    cat >&2 <<EOT
[DEV] > MANUAL
---
script path: $0

manual extract (matching '[man]' / excluding '#@!') with line number:

$manlines

---
[$(get_signature)]
EOT
    exit 0
}
export -f get_manual_developer
export TAG_MAN='\[man\]'
export TAG_EXCLUDE='#@!'

## [man][fct] get_options_list () : display lines with a '[man]' mark
get_options_list () {
    local filepath="${1:-$0}"
    local linenb_opts_first=$(grep -n "${TAG_OPTS}" $filepath | grep -v 'export ' | head -n1 | cut -d: -f1)
    local opts_lines=$(cat $filepath | sed "1,${linenb_opts_first}d;/${TAG_OPTS}/,\$d" | sed -e 's/^#//' );
    local line_opt line_comment
    local -a option_names=()
    local -a option_comments=()
    local line_lgt=0
    local max_lgt=0
    while read -r line
    do
        if [[ "$line" == '-'* ]]; then
            line_opt=$(echo "$line" | cut -d')' -f1);
            line_comment=$(echo "$line" | grep '#' | cut -d'#' -f2);
            line_opt="$(echo "$line_opt" | sed -e 's/=\*/=<arg>/g' -e 's/|/, /g')"
            option_names+=( "$line_opt" )
            option_comments+=( "$line_comment" )
            line_lgt="${#line_opt}"
            [ $line_lgt -gt $max_lgt ] && max_lgt=$line_lgt;
        fi
    done < <(echo "$opts_lines")

    local options_string=''
    for i in "${!option_names[@]}"; do
        printf "        %s%$((max_lgt+2-${#option_names[i]}))s:%s\n" "${option_names[i]}" " " "${option_comments[i]}"
    done

    exit 0
}
export -f get_options_list
export TAG_OPTS='#_opts_#'

## [man][fct] treat_arguments ( $* ) : treat command line arguments
treat_arguments () {
    local ARG_PARAM
    while [ $# -gt 0 ]; do
        ARG_PARAM="$(cut -d'=' -f2 <<< "$1")"
        case "$1" in
#_opts_#
            # flag options & settings
            -v|--verbose) VERBOSE=$((VERBOSE + 1)) ;; # increase verbosity
            -q|--quiet) VERBOSE=$((VERBOSE - 1)) ;; # decrease verbosity
            -x|--dry-run|--check) DRYRUN=true ;; # enable "dry-run" mode (nothing is actually done)
            -l|--log) LOGGING=true ;; # enable logging
            -L=*|--log-file=*) LOGFILE="$ARG_PARAM" ;; # set the logfile path (default is '$0.log')

            # library strings
            --help) get_help ;; # display help string
            --version) get_version ;; # display version string
            --manual) get_manual ;; # display long documentation string

            # library development tools
            --debug) DEVDEBUG=true ;; # enable debug mode
            --dev-manual) get_manual_developer ;; # display developement manual
            --dev-functions) typeset -F ;; # display a list of available functions
            --lib-manual) get_manual $LIB_SCRIPT_PATH ;; # display library developement manual
            --lib-dev-manual) get_manual_developer $LIB_SCRIPT_PATH ;; # display library list of available functions
#_opts_#
            *) break ;;
        esac
        shift
    done
    export VERBOSE DRYRUN DEVDEBUG LOGGING LOGFILE
    set - $CMD_ARGS
}
export -f treat_arguments

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
[DEBUG - $(get_signature)]
[LIB - ${LIB_SCRIPT_NAME} - v. ${LIB_SCRIPT_VERSION}]
EOT
}
export -f debug

#######################################################################
## [man] Library of functions for errors management

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
[$(get_signature)]
EOT
    exit $SCRIPT_STATUS
}
export -f error_throw
export SCRIPT_STATUS

## [man][fct] build_error_dev_output ( str='' ) : development error manager
build_error_dev_output () {
    cat >&2 <<EOT
[DEV ERROR] > $*
---
exit status: $SCRIPT_STATUS

stack backtrace:
$(get_backtrace)

---
[$(get_signature)]
EOT
}
export -f build_error_dev_output

## [man][fct] error_dev ( str='' ) : development error manager
error_dev () {
    local status=$?
    [ $SCRIPT_STATUS -eq 0 ] \
        && SCRIPT_STATUS=127 \
        || SCRIPT_STATUS=$((SCRIPT_STATUS + 1)) \
    ;
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    log_write error_dev "$* - exit status $SCRIPT_STATUS";
    build_error_dev_output "$*"
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
# trap 'error_trapped ERR $?' ERR
# trap 'error_trapped SIGINT $?' SIGINT

## [man][fct] error_trapped ( <type> <status> [message] ) : trapped errors
error_trapped () {
    local type="$1"
    shift
    local status="$1"
    shift
    [ $status -ne 0 ] && SCRIPT_STATUS=$status
    log_write signal_trapped "[$type] $* - exit status $SCRIPT_STATUS";
    build_error_dev_output "TRAPPED SIGNAL ($type) > $*"
    exit $SCRIPT_STATUS
}
export -f error_trapped

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

# error_dev aliases
error_dev_missing_argument() { error_dev "missing argument > $*"; }
export -f error_dev_missing_argument

#######################################################################
## [man] Library of internal functions

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

#######################################################################
## [man] When the library is called directly...

if [ "$0" == "$LIB_SCRIPT_PATH" ]; then
    LIB_DIRECT=true
    SCRIPT_VERSION="$LIB_SCRIPT_VERSION"
    SCRIPT_LICENSE="$LIB_SCRIPT_LICENSE"
    SCRIPT_PATH="$LIB_SCRIPT_PATH"
    SCRIPT_NAME="$LIB_SCRIPT_NAME"
    SCRIPT_PRESENTATION="$LIB_SCRIPT_PRESENTATION"
    SCRIPT_USAGE_SHORT="$LIB_SCRIPT_USAGE_SHORT"
    SCRIPT_USAGE="$LIB_SCRIPT_USAGE"
    [ $# -eq 0 ] && get_help;
    treat_arguments $*
fi

#######################################################################
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
#       wget -O library-picas.bash https://raw.githubusercontent.com/e-picas/binaries/master/library-picas.bash
#       wget -O my-script.sh https://raw.githubusercontent.com/e-picas/binaries/master/library-picas-template.bash
#       vi my-script.sh
#       # ...
#       bash my-script.sh
# 
# ### Library & template features
# 
# This library intends to be a kind of framework to work with
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
# ### Library help
#
# To get some more help from the library itself, you can begin running:
#
#       library-picas.bash --help
#       # or
#       library-picas.bash --manual
#       # or
#       library-picas.bash --dev-manual
#       # or
#       library-picas.bash --dev-functions
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
