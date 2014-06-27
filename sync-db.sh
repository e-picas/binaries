#!/bin/bash
#
# sync-db.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
#
# Prepare or synchornize a backup of a global databases set by `rsync`
#
# - if the backup doesn't exist, it will be created (action "clone")
# - if it already exists, the original will be re-synchronized (action "sync")

# set to `true` for dry-run
# cf. option "-x"
_DRYRUN=false

# set to `true` to be verbose
# cf. option "-v"
_VERBOSE=false

# set to true to debug
# cf. option "-z"
_DEBUG=false

# options for cmds
_RSYNCOPTS='-vh --compress --links --perms --owner --archive --recursive'
_CPOPTS='-v --preserve --no-dereference --recursive'

# arguments
_CLONEDIR='mysql-clone'
_ORIGDIR='mysql'
_DBHOME='/var/lib/'
_DBNAME=''
_ACTION='sync'

# usage string
USAGE=$(cat <<EOT
_
usage:
    $0 [-h|x|v] [-c=${_CLONEDIR}] [-o=${_ORIGDIR}] [--home=${_DBHOME}] [-d=db name] <action=sync>

action in:
    clone               : create a fresh clone (existing one will be deleted)
    sync                : synchronize existing clone with database(s)
    update-clone        : update an existing clone with current original databases state

options:
    -x|--dry-run        : enable debug (infos are written to STDOUT but nothing is done)
    -v|--verbose        : increase script's verbosity
    -c|--clone-dir      : directory of the clone of the original databases (default is '${_CLONEDIR}')
    -o|--original-dir   : original databases directory (default is '${_ORIGDIR}')
    -d|--db             : name of a database to synchronize ; leave empty to synchronize all databases (default is '${_DBNAME}')
    --home              : root home directory of databases and clone (default is '${_DBHOME}')
    -h                  : get this help message

(always use notation "-o=xxx" or "--opt=xxx")
_
EOT
);

# options
options=("$@")
OPTIND=1
while getopts ":zhxvc:o:d:-:" OPTION "${options[@]}"; do
    OPTARG="${OPTARG#=}"
    case ${OPTION} in
        h)
            echo "${USAGE}"
            exit 0
            ;;
        v)
            export _VERBOSE=true
            ;;
        x)
            export _DRYRUN=true
            ;;
        z)
            export _DEBUG=true
            ;;
        c)
            export _CLONEDIR="${OPTARG}"
            ;;
        o)
            export _ORIGDIR="${OPTARG}"
            ;;
        d)
            export _DBNAME="${OPTARG}"
            ;;
        -)
            LONGOPT="${OPTARG#=}"
            if [[ "${LONGOPT}" =~ .*=.* ]]; then LONGOPT="${LONGOPT%=*}"; fi
            LONGOPT=$(echo "${LONGOPT}" | cut -d " " -f1)
            if [[ "${OPTARG}" =~ .*=.* ]]
                then LONGOPTARG="${OPTARG#*=}"
                else LONGOPTARG=$(echo "${OPTARG}" | cut -d " " -f2-)
            fi
            case ${OPTARG} in
                help)
                    echo "${USAGE}"
                    exit 0
                    ;;
                verbose)
                    export _VERBOSE=true
                    ;;
                dry-run)
                    export _DRYRUN=true
                    ;;
                clone-dir*)
                    export _CLONEDIR="${LONGOPTARG}"
                    ;;
                original-dir*)
                    export _ORIGDIR="${LONGOPTARG}"
                    ;;
                db*|database*)
                    export _DBNAME="${LONGOPTARG}"
                    ;;
                home*)
                    export _DBHOME="${LONGOPTARG}"
                    ;;
                *)
                    echo "unknown option '${OPTARG:-OPTION}' !"
                    echo "${USAGE}"
                    exit 1
                    ;;
            esac ;;
        :)
            if [ -n ${OPTARG} ]
            then
                export _ACTION="${OPTARG}"
            fi
            ;;
        *)
            echo "unknown option '${OPTARG:-OPTION}' !"
            echo "${USAGE}"
            exit 1
            ;;
    esac
    shift
done
[ ! -z ${1} ] && export _ACTION="$1";

# must be ran as root
if [ "`id -u`" != "0" ]
then
    echo "!! > You must run this script as super-user !";
    echo "${USAGE}"
    exit 1;
fi

# check home dir
if [ ! -d ${_DBHOME} ]; then
    echo "!! > db home directory ${_DBHOME} not found!"
    echo "${USAGE}"
    exit 1
fi

# check source dir
if [ ! -d ${_DBHOME}/${_ORIGDIR} ]; then
    if [ "${_DBHOME}" != '/home/' ]&&[ -d /home/${_ORIGDIR} ]
    then
        export _DBHOME='/home/'
    else
        echo "!! > db sources ${_DBHOME}/${_ORIGDIR} not found!"
        echo "${USAGE}"
        exit 1
    fi
fi

# database
if [ "${_DBNAME}" != '' ]
then
    if [ ! -d "${_DBHOME}/${_ORIGDIR}/${_DBNAME}" ]; then
        echo "!! > database ${_DBNAME} not found!"
        echo "${USAGE}"
        exit 1
    fi
fi

# check clone dir
if [ ! -d ${_DBHOME}/${_CLONEDIR} ]&&[ "${_ACTION}" != 'clone' ]
then
    export _ACTION='clone'
    echo "> clone not found - the action is set to 'clone'"
else
    if [ "${_ACTION}" == 'clone' ]
    then
        read -p "> a clone already exists - over-write it ? [Y/n] " _resp
        _resp="${_resp:-Y}"
        if [ "${_resp}" != 'y' ]&&[ "${_resp}" != 'Y' ]
        then
            echo "_ abort"
            exit 0
        fi
    fi
fi

# action
if [ "${_ACTION}" != 'clone' ]&&[ "${_ACTION}" != 'sync' ]
then
    echo "!! > unknown action ${_ACTION} !"
    echo "${USAGE}"
    exit 1
fi

# debug
if $_DEBUG
then
    echo "## DEBUG ##"
    echo
    echo "<clone_dir>       : ${_DBHOME}/${_CLONEDIR}"
    echo "<original_dir>    : ${_DBHOME}/${_ORIGDIR}"
    echo "<db_name>         : ${_DBNAME}"
    echo "<action>          : ${_ACTION}"
    [ -d ${_CLONEDIR} ] && [ "${_ACTION}" == 'clone' ] && echo "=> the clone already exists and will be replaced";
    echo
    _resp="${_resp:-N}"
    [ "${_resp}" != 'y' ] && [ "${_resp}" != 'Y' ] && exit 0;
fi

# let's go
cd ${_DBHOME}

if $_VERBOSE; then echo "stopping mysql"; fi
service mysql stop
if [ "${?}" -ne "0" ]
then
    echo "!! > error"
    exit 1
fi

if [ "${_ACTION}" == 'sync' ]; then
    if $_VERBOSE; then echo "syncing clone in original"; fi
    if [ "${_DBNAME}" != '' ]
    then
        if $_DRYRUN
        then
            echo "> dry-run: rsync -avrlzh ${_CLONEDIR}/${_DBNAME}/ ${_ORIGDIR}/${_DBNAME}/"
        else
            rsync ${_RSYNCOPTS} "${_CLONEDIR}/${_DBNAME}/" "${_ORIGDIR}/${_DBNAME}/"
        fi
    else
        if $_DRYRUN
        then
            echo "> dry-run: rsync -avrlzh ${_CLONEDIR}/${_ORIGDIR}/"
        else
            rsync ${_RSYNCOPTS} "${_CLONEDIR}/" "${_ORIGDIR}/"
        fi
    fi
    if $_VERBOSE; then echo "restarting mysql"; fi
    service mysql start

elif [ "${_ACTION}" == 'update-clone' ]; then
    if $_VERBOSE; then echo "updating clone"; fi
    if [ "${_DBNAME}" != '' ]
    then
        if $_DRYRUN
        then
            echo "> dry-run: rsync ${_RSYNCOPTS} ${_ORIGDIR}/${_DBNAME}/ ${_CLONEDIR}/${_DBNAME}/"
        else
            rsync ${_RSYNCOPTS} "${_ORIGDIR}/${_DBNAME}/" "${_CLONEDIR}/${_DBNAME}/"
        fi
    else
        if $_DRYRUN
        then
            echo "> dry-run: rsync ${_RSYNCOPTS} ${_ORIGDIR}/ ${_CLONEDIR}/"
        else
            rsync ${_RSYNCOPTS} "${_ORIGDIR}/" "${_CLONEDIR}/"
        fi
    fi

elif [ "${_ACTION}" == 'clone' ]; then
    if [ -d ${_CLONEDIR} ]; then
        if $_VERBOSE; then echo "removing existing backup"; fi
        if $_DRYRUN
        then
            echo "> dry-run: rm -rf ${_CLONEDIR}"
        else
            rm -rf ${_CLONEDIR}
        fi
    fi
    if $_VERBOSE; then echo "creating a clone of the original database"; fi
    if $_DRYRUN
    then
        echo "> dry-run: cp ${_CPOPTS} ${_ORIGDIR} ${_CLONEDIR}"
    else
        cp ${_CPOPTS} ${_ORIGDIR} ${_CLONEDIR}
    fi

fi

if $_VERBOSE; then echo "restarting mysql"; fi
service mysql start
if [ "${?}" -ne "0" ]
then
    echo "!! > error"
    exit 1
fi

echo "> ok --"

# Endscript
