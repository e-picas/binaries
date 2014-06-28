#!/bin/bash
#
# cleanup.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# A simple shell utility to fix UNIX rights on files, directories, secret files and binaries
# and to clean up OS files on a working directory.
#

# Options:
#
# V version
# h help
# i info usage
# v verbose
# q quiet
# x dry-run
# d directories chmod
# f files chmod
# b binaries chmod
# a secret chmod
# s shell scripts masks
# z shell scripts directories
# k keys secure keys masks
# m masks list of files to remove
# debug for special debug (dev tool)
#

set -f
declare -rx VERSION="1.0@dev"

###################### flags enabled by script options
export VERBOSE=false
export QUIET=false
export DRYRUN=false
export DEBUG=false

###################### default settings
declare -x HERE=`pwd`
declare -x WORKING_DIR="$HERE"
declare -x FILES_CHMOD
declare -x DIRS_CHMOD
declare -x SECRET_CHMOD
declare -x BINS_CHMOD
declare -ax REMOVE_MASKS
declare -ax SCRIPT_MASKS
declare -ax SCRIPT_DIRS
declare -rx FILES_CHMOD=0644
declare -rx DIRS_CHMOD=0755
declare -rx SECRET_CHMOD=0600
declare -rx BINS_CHMOD="a+x"
declare -rax DEFAULT_REMOVE_MASKS=( .DS_Store .AppleDouble .LSOverride .Spotlight-V100 .Trashes Icon ._* *~ *~lock* Thumbs.db ehthumbs.db Desktop.ini .project .buildpath )
declare -rax DEFAULT_SCRIPT_MASKS=( *.sh *.exe *.pl )
declare -rax DEFAULT_SCRIPT_DIRS=( bin )
declare -rax DEFAULT_KEY_MASKS=( *.key )
if [ ! -n "$REMOVE_MASKS" ]; then export REMOVE_MASKS=( "${DEFAULT_REMOVE_MASKS[@]}" ); fi
if [ ! -n "$SCRIPT_MASKS" ]; then export SCRIPT_MASKS=( "${DEFAULT_SCRIPT_MASKS[@]}" ); fi
if [ ! -n "$SCRIPT_DIRS" ]; then export SCRIPT_DIRS=( "${DEFAULT_SCRIPT_DIRS[@]}" ); fi
if [ ! -n "$KEY_MASKS" ]; then export KEY_MASKS=( "${DEFAULT_KEY_MASKS[@]}" ); fi
if [ ! -n "$FILES_CHMOD" ]; then export FILES_CHMOD="${DEFAULT_FILES_CHMOD}"; fi
if [ ! -n "$DIRS_CHMOD" ]; then export DIRS_CHMOD="${DEFAULT_DIRS_CHMOD}"; fi
if [ ! -n "$BINS_CHMOD" ]; then export BINS_CHMOD="${DEFAULT_BINS_CHMOD}"; fi
if [ ! -n "$SECRET_CHMOD" ]; then export SECRET_CHMOD="${DEFAULT_SECRET_CHMOD}"; fi

###################### fcts

#### usage ()
usage () {
    echo "    $0  [-h | --help | help]  [-i | --usage | usage]"
    echo "          [-x | --dry-run]  [-v | --verbose]  [-q | --quiet]  [-V]"
    echo "          [-d | --chmod-dirs =CHMOD]  [-f | --chmod-files =CHMOD]  [-a | --chmod-secret =CHMOD]  [-b | --chmod-bins =CHMOD]"
    echo "          [-s | --shells =MASKS LIST]  [-z | --bin =BIN DIRS LIST]  [-m | --mask =MASKS LIST]  [-k | --keys =MASKS LIST]"
}

#### help ()
help () {
    echo "## HELP - Clean up a directory fixing rights and removing unused files"
    echo
    echo "This will process a (hard) 'cleaning' on the working directory:"
    echo "    - reset UNIX rights on ALL files and directories"
    echo "    - make binaries executables ('a+x')"
    echo "    - remove some unwanted files"
    echo
    echo "usage:"
    usage
    echo
    echo "options:"
    echo "    -f | --chmod-files  =CHMOD        CHMOD value to set on all files - default is '${DEFAULT_FILES_CHMOD}'"
    echo "    -d | --chmod-dirs   =CHMOD        CHMOD value to set on all directories - default is '${DEFAULT_DIRS_CHMOD}'"
    echo "    -b | --chmod-bins   =CHMOD        CHMOD value to set on binaires - default is '${DEFAULT_BINS_CHMOD}'"
    echo "    -a | --chmod-keys   =CHMOD        CHMOD value to set on secret files - default is '${DEFAULT_SECRET_CHMOD}'"
    echo "    -s | --shells       =[ML*]        List of masks to search shell scripts and enable them as 'a+x' - defaults are:"
    echo "                                          '${DEFAULT_SCRIPT_MASKS[@]}'"
    echo "    -z | --bin          =[ML*]        List of directories to enable all their contents as shell scripts - defaults are:"
    echo "                                          '${DEFAULT_SCRIPT_DIRS[@]}'"
    echo "    -k | --keys         =[ML*]        List of masks to search keys or secret files - defaults are:"
    echo "                                          '${DEFAULT_KEY_MASKS[@]}'"
    echo "    -m | --mask         =[ML*]        List of masks to search temporary or OS files to remove - defaults are:"
    echo "                                          '${DEFAULT_REMOVE_MASKS[@]}'"
    echo "    -w | --working-dir                Define the directory path to work on - default is current directory"
    echo "    -v | --verbose                    Increase script's verbosity"
    echo "    -q | --quiet                      Decrease script's verbosity (no output except errors)"
    echo "    -x | --dry-run                    Make a dry run (nothing is done)"
    echo "    -i | --usage                      Show simple usage info"
    echo "    -h | --help                       Show this help info"
    echo
    echo "You MUST use the equal sign for long options: '--long-option=\"my value\"'."
    echo "[*ML] : 'masks list'"
    echo "      : lists arguments can be defined as a shell list (space separated) surrounded by double-quotes or as a comma separated list of values."
    echo "      : lists arguments can be appended to defaults using a '+' sign item."
    echo
}

#### debug ()
debug () {
    oldifs=$IFS
    IFS=','
    echo
    echo "---- debug"
    echo "resulting request        : $0 $*"
    echo "working dir is           : $WORKING_DIR"
    echo
    echo "---- flags (overloaded by script options)"
    echo "dry-run                  : $DRYRUN"
    echo "verbose                  : $VERBOSE"
    echo "quiet                    : $QUIET"
    echo
    echo "---- env (overloaded by user)"
    echo "DIRS_CHMOD               : $DIRS_CHMOD"
    echo "FILES_CHMOD              : $FILES_CHMOD"
    echo "SECRET_CHMOD             : $SECRET_CHMOD"
    echo "BINS_CHMOD               : $BINS_CHMOD"
    echo "SCRIPT_MASKS             : ${SCRIPT_MASKS[*]}"
    echo "SCRIPT_DIRS              : ${SCRIPT_DIRS[*]}"
    echo "KEY_MASKS                : ${KEY_MASKS[*]}"
    echo "REMOVE_MASKS             : ${REMOVE_MASKS[*]}"
    echo
    echo "----"
    echo "Use option '-h' for help"
    echo
    IFS=$oldifs
}

#### error ()
error () {
    echo
    usage
    exit 1
}

#### errorStr ( str )
errorStr () {
    echo "!! - ${1} [${BASH_LINENO[0]}]"
    echo
    usage
    exit 1
}

#### doCleanUp ( dir )
doCleanUp () {
    local wd="$1"
    local oldpwd=`pwd`
    if [ -n "$wd" ]; then
        cmd="cd $wd"
        if $VERBOSE; then echo "$cmd"; fi
        eval "$cmd";
    fi
    if [ "${#REMOVE_MASKS[@]}" -gt 0 ]; then
        for FNAME in "${REMOVE_MASKS[@]}"; do
            cmd="find . -type f -name '$FNAME' -exec rm {} \;"
            if $DRYRUN; then echo "$cmd"; else
                if $VERBOSE; then echo "$cmd"; fi
                eval "$cmd";
            fi;
        done
    fi
    if [ -n "$DIRS_CHMOD" ]; then
        cmd="find . -type d -exec chmod $DIRS_CHMOD {} \;"
        if $DRYRUN; then echo "$cmd"; else
            if $VERBOSE; then echo "$cmd"; fi
            eval "$cmd";
        fi;
    fi
    if [ -n "$FILES_CHMOD" ]; then
        cmd="find . -type f -exec chmod $FILES_CHMOD {} \;"
        if $DRYRUN; then echo "$cmd"; else
            if $VERBOSE; then echo "$cmd"; fi
            eval "$cmd";
        fi;
    fi
    if [ "${#SCRIPT_MASKS[@]}" -gt 0 ]; then
        for SNAME in "${SCRIPT_MASKS[@]}"; do
            cmd="find . -type f -name '$SNAME' -exec chmod $BINS_CHMOD {} \;"
            if $DRYRUN; then echo "$cmd"; else
                if $VERBOSE; then echo "$cmd"; fi
                eval "$cmd";
            fi;
        done
    fi
    if [ "${#SCRIPT_DIRS[@]}" -gt 0 ]; then
        for DNAME in "${SCRIPT_DIRS[@]}"; do
            cmd="find . -type d -name '$DNAME' -print | xargs -I % chmod $BINS_CHMOD %/*;"
            if $DRYRUN; then echo "$cmd"; else
                if $VERBOSE; then echo "$cmd"; fi
                eval "$cmd";
            fi;
        done
    fi
    if [ "${#KEY_MASKS[@]}" -gt 0 ]; then
        for KNAME in "${KEY_MASKS[@]}"; do
            cmd="find . -type f -name '$KNAME' -exec chmod $SECRET_CHMOD {} \;"
            if $DRYRUN; then echo "$cmd"; else
                if $VERBOSE; then echo "$cmd"; fi
                eval "$cmd";
            fi;
        done
    fi
    if [ -n "$wd" ]; then cd "$oldpwd"; fi
    return 0
}

#### getlongoption ( "$x" )
## echoes the name of a long option
## see http://github.com/atelierspierrot/piwi-bash-library
getlongoption () {
    local arg="$1"
    if [ -n "$arg" ]; then
        if [[ "$arg" =~ .*=.* ]]; then arg="${arg%=*}"; fi
        echo "$arg" | cut -d " " -f1
        return 0
    fi
    return 1
}

#### getlongoptionarg ( "$x" )
## echoes the argument of a long option
## see http://github.com/atelierspierrot/piwi-bash-library
getlongoptionarg () {
    local arg="$1"
    if [ -n "$arg" ]; then
        if [[ "$arg" =~ .*=.* ]]
            then arg="${arg#*=}"
            else arg=$(echo "$arg" | cut -d " " -f2-)
        fi
        echo "$arg"
        return 0
    fi
    return 1
}

#### getSafeList ( default_name array[@] )
getSafeList () {
    local oldifs=$IFS
    if [ "$#" -lt 2 ]; then echo ""; return 0; fi
    read -ra default_varname <<< "${!1}"
    IFS=' ' read -ra args <<< "$2"
    declare -a myarray=()
    for item in "${args[@]}"; do
        if [ "$item" != "${item/,/}" ]; then
            IFS=',' read -ra myitems <<< "$item"
            for subitem in "${myitems[@]}"; do myarray+=( $subitem ); done
            IFS=$oldifs
        else
            myarray+=( $item )
        fi
    done
    IFS=$oldifs
    local counter=0
    for sub in "${myarray[@]}"; do
        if [ "$sub" = '+' ]; then
            unset myarray["$counter"]
            myarray+=( "${default_varname[@]}" )
        fi
        counter=$((counter+1))
    done
    echo "${myarray[@]}"
    return 0
}

###################### process

# options
if [ -n "$1" ]; then
    if [ "$1" = 'help' ]; then actiontodo='help';
    elif [ "$1" = 'usage' ]; then actiontodo='usage';
    elif [ "$1" = 'debug' ]; then export DEBUG=true;
    fi
fi

OPTIND=1
while getopts "a:b:d:f:him:q:s:Vvw:xz:-:" OPTION; do
    OPTARG="${OPTARG#=}"
    case $OPTION in
    # common options
        a) export SECRET_CHMOD="$OPTARG";;
        b) export BINS_CHMOD="$OPTARG";;
        d) export DIRS_CHMOD="$OPTARG";;
        f) export FILES_CHMOD="$OPTARG";;
        h) export actiontodo='help';;
        i) export actiontodo='info';;
        m) export REMOVE_MASKS=( $(getSafeList DEFAULT_REMOVE_MASKS[@] "${OPTARG}") );;
        q) export VERBOSE=false; export QUIET=true;;
        s) export SCRIPT_MASKS=( $(getSafeList DEFAULT_SCRIPT_MASKS[@] "${OPTARG}") );;
        v) export VERBOSE=true; export QUIET=false;;
        V) echo "$VERSION"; exit 0;;
        w) export WORKING_DIR="$OPTARG";;
        x) export DRYRUN=true;;
        z) export SCRIPT_DIRS=( $(getSafeList DEFAULT_SCRIPT_DIRS[@] "${OPTARG}") );;
        -)  LONGOPT="`getlongoption \"${OPTARG}\"`"
            LONGOPTARG="`getlongoptionarg \"${OPTARG}\"`"
            case $OPTARG in
                help) export actiontodo='help';;
                info|usage) export actiontodo='usage';;
                verbose) export VERBOSE=true; export QUIET=false;;
                quiet) export VERBOSE=false; export QUIET=true;;
                dry-run) export DRYRUN=true;;
                chmod-dir*) export DIRS_CHMOD="$LONGOPTARG";;
                chmod-file*) export FILES_CHMOD="$LONGOPTARG";;
                chmod-bin*) export BINS_CHMOD="$LONGOPTARG";;
                chmod-key*|chmod-secret*) export SECRET_CHMOD="$LONGOPTARG";;
                shell*|script*) export SCRIPT_MASKS=( $(getSafeList DEFAULT_SCRIPT_MASKS[@] "${LONGOPTARG[@]}") );;
                bin*) export SCRIPT_DIRS=( $(getSafeList DEFAULT_SCRIPT_DIRS[@] "${LONGOPTARG[@]}") );;
                mask*|list*) export REMOVE_MASKS=( $(getSafeList DEFAULT_REMOVE_MASKS[@] "${LONGOPTARG[@]}") );;
                key*|secret*) export KEY_MASKS=( $(getSafeList DEFAULT_KEY_MASKS[@] "${LONGOPTARG[@]}") );;
                working*) export WORKING_DIR="$LONGOPTARG";;
                debug) export DEBUG=true;;
                -) break;;
                *) error;;
            esac ;;
        *) error;;
    esac
done

# action
if [ -n "$actiontodo" ]; then
    if [ "$actiontodo" = 'help' ]; then help; exit 0;
    elif [ "$actiontodo" = 'usage' ]; then usage; exit 0;
    fi
fi

# debug
if $DEBUG; then debug "$*"; exit 0; fi;

# test
if [ ! -d "$WORKING_DIR" ]; then
    errorStr "defined working directory '$WORKING_DIR' does not exist"
fi

# process
if $DRYRUN; then
    $VERBOSE && echo "[dry-run] -- > would process on '$HERE':"
    doCleanUp $WORKING_DIR && cd $HERE
    $VERBOSE && echo "----"
    exit 0
else
    $VERBOSE && echo "${SCRIPTOPTS}-- > processing on '$HERE'"
    doCleanUp $WORKING_DIR && cd $HERE
    $QUIET || echo "_ ok"
fi

exit 0
# Endfile