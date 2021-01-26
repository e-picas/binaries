#!/bin/bash
#!/bin/bash
#
# bash script model
#
set -e
set -o errtrace

#######################################################################
# defaults
VERBOSE=false
DRYRUN=false
SCRIPT_STATUS=0
BASEDIR=$PWD

# script infos
SCRIPT_VERSION="0.0.1-dev"
SCRIPT_NAME="$(basename $0)"
SCRIPT_PRESENTATION="This script is a bash script model."
SCRIPT_USAGE_SHORT=$(cat <<EOT
usage:  $SCRIPT_NAME [-h|-v|-x] [--option[=arg]] <arguments>
        $SCRIPT_NAME -h | --help
EOT
);
SCRIPT_USAGE=$(cat <<EOT
$SCRIPT_USAGE_SHORT

options:
        --option[=arg]       # to do what ?
        -h|--help            # get help
        -v|--verbose         # increase verbosity
        -x|--dry-run|--check # enable a "dry-run" (nothing is actually done)

Options arguments MUST be written after an equal sign: '--option=argument'.
Options can NOT be grouped: '-v -x'.
EOT
);

#######################################################################
# library (list of fcts to call after)

# get_help ()
get_help () {
    cat <<EOT
--- ${SCRIPT_NAME} - v. ${SCRIPT_VERSION}

${SCRIPT_PRESENTATION}

${SCRIPT_USAGE}
---
EOT
}
export -f get_help

# throw_error ( str='' )
throw_error () {
    local status=$?
    SCRIPT_STATUS=$((SCRIPT_STATUS + 1))
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    cat >&2 <<EOT
error > $*
---
${SCRIPT_USAGE_SHORT}
--- [${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
    exit $SCRIPT_STATUS
}
export -f throw_error
export SCRIPT_STATUS

# dev_error ( str='' )
dev_error () {
    local status=$?
    [ $SCRIPT_STATUS -eq 0 ] \
        && SCRIPT_STATUS=127 \
        || SCRIPT_STATUS=$((SCRIPT_STATUS + 1)) \
    ;
    [ $status -ne 0 ] && SCRIPT_STATUS=$((SCRIPT_STATUS + $status))
    local backtrace=$(get_backtrace)
    cat >&2 <<EOT
dev error > $*
---
exit status > $SCRIPT_STATUS
backtrace >
$backtrace

--- [${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]
EOT
    exit $SCRIPT_STATUS
}
export -f dev_error

# trap ERR), script exit (EXIT), and the interrupt (SIGINT), terminate (SIGTERM), and kill (KILL
# trapped signals:
#   errors (ERR)
#   script exit (EXIT)
#   interrupt (SIGINT)
#   terminate (SIGTERM)
#   kill (KILL)
trap 'dev_error $?' ERR

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

# verbose_echo ( str )
verbose_echo () {
    [ $# -eq 0 ] && dev_error_missing_argument "usage: ${FUNCNAME[0]} <str>";
    $VERBOSE && echo "info > $*";
}
export -f verbose_echo
export VERBOSE

# get_absolute_path ( path )
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
BASEDIR="$(get_absolute_path "${BASH_SOURCE[0]}")"

# environment vars debugging
debug() {
    local backtrace=$(get_backtrace)
    cat <<EOT

--- debug >
exit status: $SCRIPT_STATUS
verbosity: $VERBOSE
dry-run: $DRYRUN
--- backtrace >
$backtrace
--- [${SCRIPT_NAME} - v. ${SCRIPT_VERSION}]

EOT
}
export -f debug

#######################################################################

# if arguments are required
[ $# -eq 0 ] && throw_error 'arguments are required';

# arguments
while [ $# -gt 0 ]; do
    ARG_PARAM="$(cut -d'=' -f2 <<< "$1")"
    case "$1" in
        # user options...
        --option=*) VAR="$ARG_PARAM" ;;
        # you should NOT change below
        -h|--help) get_help; exit 0 ;;
        -v|--verbose) VERBOSE=true ;;
        -x|--dry-run|--check) DRYRUN=true ;;
        -*) throw_error "unknown parameter $1" ;;
        *) break ;;
    esac
    shift
done

mask_find="$1"
mask_replace="${2:-false}"
working_basedir="${3:-$HOME}"

export VERBOSE DRYRUN SCRIPT_STATUS BASEDIR

# let's go for scripting! ;)






debug
echo '-- end of script'
exit 0
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=sh