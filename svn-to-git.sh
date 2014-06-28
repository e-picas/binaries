#!/bin/bash
#
# svn-to-git.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# A SVN to GIT utility using internal `git-svn`, retrieving *branches* and *tags* and
# cleaning the new GIT clone before to push it on a distant remote.
# 
# For the original `git-svn` manual, see <http://git-scm.com/docs/git-svn>.
#
# See <https://github.com/piwi/binaries/tree/svn-to-git-work> for process info
#

# Usage:
#
#    svn-to-git.sh -h
#    svn-to-git.sh (options) local_name svn_name git_name type dirs,list hook
#
# Environment variables:
#
#    svn-to-git.sh -x
#
# All environment variables are overloadable writing:
#
#    export MSG_GITFILTER="my personal value" && svn-to-git.sh ...
#
# Error messages are followed by throwing line number.
#

declare -rx VERSION="1.0@dev"

###################### flags enabled by script options
export _DEBUG=false
export _VERBOSE=false
export _QUIET=false
export _DRYRUN=false
export _TESTMODE=false
export _LOCALCLEANMODE=false
export _SERVERCLEANMODE=false

###################### default settings
declare -x HERE=`pwd`
declare -x _DIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
declare -x GLOBAL_OPTS
declare -x BASE_DIR
declare -ax CLEANUP_NAMES
declare -x SVNURL
declare -x SVNROOT
declare -x SVN_BRANCH
declare -x SVN_PREFIX
declare -x DELETE_SVN_REMOTES
declare -x GITURL
declare -x GITROOT
declare -x GITIGNORE_FILEPATH
declare -x GITIGNORE_FILENAME
declare -x KEEP_IGNOREFILE
declare -x GITAUTHORS_FILEPATH
declare -x GITAUTHORS_FILENAME
declare -x KEEP_AUTHORSFILE
declare -x MSG_GITFILTER
declare -x ENV_GITFILTER
declare -x BRANCHES_RECOVERY
declare -x TAGS_RECOVERY
declare -x NO_METADATA
declare -x IS_SSH_SERVER
declare -x SERVER
declare -rx DEFAULT_BASE_DIR="tmp/"
declare -rax DEFAULT_CLEANUP_NAMES=( .DS_Store .AppleDouble .LSOverride .Spotlight-V100 .Trashes Icon ._* *~ *~lock* Thumbs.db ehthumbs.db Desktop.ini .project .buildpath )
declare -rx DEFAULT_SVNURL="file:///var/svn/"
declare -rx DEFAULT_SVNROOT=""
declare -rx DEFAULT_SVN_BRANCH="svn-backup"
declare -rx DEFAULT_SVN_PREFIX="svn/"
declare -rx DEFAULT_DELETE_SVN_REMOTES=true
declare -rx DEFAULT_GITURL="file:///var/git/"
declare -rx DEFAULT_GITROOT=""
declare -rx DEFAULT_GITIGNORE_FILENAME=".gitignore"
declare -rx DEFAULT_KEEP_IGNOREFILE=false
declare -rx DEFAULT_GITAUTHORS_FILENAME=".gitauthors"
declare -rx DEFAULT_KEEP_AUTHORSFILE=false
declare -rx DEFAULT_BRANCHES_RECOVERY="git branch -r | grep -v 'tags/' | grep -v 'trunk' | grep -v 'origin' | sed 's, ,,' | sed 's,branches/,,'"
declare -rx DEFAULT_TAGS_RECOVERY="git branch -r | grep 'tags/' | grep -v '@' | sed 's, ,,'  | sed 's,tags/,,'"
declare -rx DEFAULT_NO_METADATA=false
declare -rx DEFAULT_IS_SSH_SERVER=false

if [ ! -n "$GLOBAL_OPTS" ]; then export GLOBAL_OPTS="$DEFAULT_GLOBAL_OPTS"; fi
if [ ! -n "$BASE_DIR" ]; then export BASE_DIR="$DEFAULT_BASE_DIR"; fi
if [ ! -n "$SVN_BRANCH" ]; then export SVN_BRANCH="$DEFAULT_SVN_BRANCH"; fi
if [ ! -n "$CLEANUP_NAMES" ]; then export CLEANUP_NAMES=( "${DEFAULT_CLEANUP_NAMES[@]}" ); fi
if [ ! -n "$SVNURL" ]; then export SVNURL="$DEFAULT_SVNURL"; fi
if [ ! -n "$SVNROOT" ]; then export SVNROOT="$DEFAULT_SVNROOT"; fi
if [ ! -n "$GITURL" ]; then export GITURL="$DEFAULT_GITURL"; fi
if [ ! -n "$GITROOT" ]; then export GITROOT="$DEFAULT_GITROOT"; fi
if [ -z $IS_SSH_SERVER ]; then export IS_SSH_SERVER=$DEFAULT_IS_SSH_SERVER; fi
if [ -z $NO_METADATA ]; then export NO_METADATA=$DEFAULT_NO_METADATA; fi
if [ ! -n "$SVN_PREFIX" ]; then export SVN_PREFIX="$DEFAULT_SVN_PREFIX"; fi
if [ -z $DELETE_SVN_REMOTES ]; then export DELETE_SVN_REMOTES=$DEFAULT_DELETE_SVN_REMOTES; fi
if [ -z $KEEP_AUTHORSFILE ]; then export KEEP_AUTHORSFILE=$DEFAULT_KEEP_AUTHORSFILE; fi
if [ ! -n "$GITAUTHORS_FILENAME" ]; then export GITAUTHORS_FILENAME="$DEFAULT_GITAUTHORS_FILENAME"; fi
if [ -z $KEEP_IGNOREFILE ]; then export KEEP_IGNOREFILE=$DEFAULT_KEEP_IGNOREFILE; fi
if [ ! -n "$GITIGNORE_FILENAME" ]; then export GITIGNORE_FILENAME="$DEFAULT_GITIGNORE_FILENAME"; fi
if [ ! -n "$BRANCHES_RECOVERY" ]; then
    export BRANCHES_RECOVERY="$DEFAULT_BRANCHES_RECOVERY"
    if [ -n "$SVN_PREFIX" ]; then export BRANCHES_RECOVERY="${BRANCHES_RECOVERY} | sed 's,${SVN_PREFIX},,'"; fi
fi
if [ ! -n "$TAGS_RECOVERY" ]; then
    export TAGS_RECOVERY="$DEFAULT_TAGS_RECOVERY"
    if [ -n "$SVN_PREFIX" ]; then export TAGS_RECOVERY="${TAGS_RECOVERY} | sed 's,${SVN_PREFIX},,'"; fi
fi

###################### fcts

#### usage ()
usage () {
    echo "    $0  [--dry-run]  [--test]  [--clean]  [--server-clean]"
    echo "          [-x | --debug | debug]  [-h | --help | help]  [-i | --usage | usage]  [-V]"
    echo "          local_name  [svn_name=local_name]  [git_name=local_name]  [type=none]  [backup_dirnames=dirA,dirB]  [pre-server-hook]"
}

#### help ()
help () {
    echo "## HELP - Assistant for svn-to-git process"
    echo
    echo "usage:"
    echo "    $0  (--options)  local_name  [svn_name=local_name]  [git_name=local_name]  [type=none]  [backup_dirnames=dirA,dirB]  [pre-server-hook]"
    echo
    echo "arguments:"
    echo "    local_name       The name of the local copy directory"
    echo "    svn_name         The name of the original SVN repository (default is the local name)"
    echo "    git_name         The name of the GIT repository to create (default is the local name - set on 'svn_name' to defaults on SVN name)"
    echo "    type             The type of the original SVN repository structure (default is 'none')"
    echo "                     can be 'classic' for 'tags/branches/trunk' or a full string between quotes like '-T mytrunk -b mybranches ...'"
    echo "    backup_dirnames  List of comma separated SVN root directories to backup in a 'svn-back' branch"
    echo "    pre-server-hook  Special hook script that will be evaluated before pushing the clone to the server"
    echo
    echo "options (TO USE FIRST):"
    echo "    --dry-run        Make a dry run"
    echo "    --test           Make a test of clone (nothing is done on remote server)"
    echo "    --clean          First clean any existing 'git_name' directory"
    echo "    --server-clean   Clean any existing 'git_name' directory on the remote server"
    echo "    --debug | -x     Debug current environment (nothing is done)"
    echo "    --usage | -i     Show simple usage info"
    echo "    --help | -h      Show this help info"
    echo "    -V               Get script version"
    echo
    echo "infos:"
    echo "    All arguments are optional except the 'local_name'. Use the dash value '-' to use default for an argument."
    echo "    The script uses a complex set of environment variables you can list with the '-x' option."
    echo
}

#### debug ()
debug () {
    echo
    echo "---- debug"
    echo "resulting request        : $0 $*"
    echo
    echo "---- flags (overloaded by script options)"
    echo "dry-run                  : $_DRYRUN"
    echo "test                     : $_TESTMODE"
    echo "clean                    : $_LOCALCLEANMODE"
    echo "server-clean             : $_SERVERCLEANMODE"
    echo
    echo "---- env (overloaded by user)"
    echo "BASE_DIR                 : $BASE_DIR"
    echo "CLEANUP_NAMES            : ${CLEANUP_NAMES[@]}"
    echo "SVNURL                   : $SVNURL"
    echo "SVNROOT                  : $SVNROOT"
    echo "SVN_BRANCH               : $SVN_BRANCH"
    echo "SVN_PREFIX               : $SVN_PREFIX"
    echo "DELETE_SVN_REMOTES       : $DELETE_SVN_REMOTES"
    echo "GITURL                   : $GITURL"
    echo "GITROOT                  : $GITROOT"
    echo "GITIGNORE_FILEPATH       : $GITIGNORE_FILEPATH"
    echo "GITIGNORE_FILENAME       : $GITIGNORE_FILENAME"
    echo "KEEP_IGNOREFILE          : $KEEP_IGNOREFILE"
    echo "GITAUTHORS_FILEPATH      : $GITAUTHORS_FILEPATH"
    echo "GITAUTHORS_FILENAME      : $GITAUTHORS_FILENAME"
    echo "KEEP_AUTHORSFILE         : $KEEP_AUTHORSFILE"
    echo "MSG_GITFILTER            : $MSG_GITFILTER"
    echo "ENV_GITFILTER            : $ENV_GITFILTER"
    echo "BRANCHES_RECOVERY        : $BRANCHES_RECOVERY"
    echo "TAGS_RECOVERY            : $TAGS_RECOVERY"
    echo "NO_METADATA              : $NO_METADATA"
    echo "IS_SSH_SERVER            : $IS_SSH_SERVER"
    echo "SERVER                   : $SERVER"
    echo
    echo "----"
    echo "Use option '-h' for help"
    echo
}

#### trailingSlash ( path )
stripTrailingSlash () {
    printf '%s' "${1%/}"
    return 0
}

#### errorStr ( str )
errorStr () {
    echo "!! - ${1} [${BASH_LINENO[0]}]"
    echo
    usage
    echo
    echo "Use option '-h' for help"
    exit 1
}

#### cleanUp ()
cleanUp () {
    find . -type d -exec chmod 0755 {} \;
    find . -type f -exec chmod 0644 {} \;
    find . -type d -name ".svn" -exec rm -rf {} \;
    for FNAME in "${CLEANUP_NAMES[@]}"; do
        find . -type f -name "$FNAME" -exec rm {} \;
    done
    return 0
}

#### processSvnToGit ()
processSvnToGit () {
    local LOCALNAME="$LOCAL_NAME"
    local LOCALDIR="${BASE_DIR}/${LOCALNAME}"
    local GITDIR="$GIT_NAME"
    local SVNDIR="$SVN_NAME"

    # clean existing, create it and cd in it
    if [ $_LOCALCLEANMODE -a -d $LOCALDIR ]; then
        echo "removing '$LOCALDIR'"
        rm -rf $LOCALDIR
    fi
    echo "creating '$LOCALDIR'"
    mkdir -p $LOCALDIR && cd $LOCALDIR && git init;

    # import required files
    local cloneopts=""
    if [ -n "$SVN_PREFIX" ]; then
        cloneopts+=" --prefix=$SVN_PREFIX"
    fi
    if [ -n "$GITIGNORE_FILEPATH" ]; then
        if [ -f $GITIGNORE_FILEPATH ]; then
            echo "importing '$GITIGNORE_FILEPATH' to '$GITIGNORE_FILENAME'"
            cp $GITIGNORE_FILEPATH $GITIGNORE_FILENAME
        fi
    fi
    if [ -n "$GITAUTHORS_FILEPATH" ]; then
        if [ -f $GITAUTHORS_FILEPATH ]; then
            echo "importing '$GITAUTHORS_FILEPATH' to '$GITAUTHORS_FILENAME'"
            cp $GITAUTHORS_FILEPATH $GITAUTHORS_FILENAME
            cloneopts+=" --authors-file=$GITAUTHORS_FILENAME"
        fi
    fi

    # svn clone with structure
    echo "cloning from '${SVNURL}/${SVNROOT}/${SVNDIR}'"
    if $NO_METADATA; then
        cloneopts+=" --no-metadata"
    fi
    if [ "$TYPE" = 'classic' ]; then
        git svn $cloneopts clone -s "${SVNURL}/${SVNROOT}/${SVNDIR}" .
    elif [ "$TYPE" = 'none' ]; then
        git svn $cloneopts clone "${SVNURL}/${SVNROOT}/${SVNDIR}" .
    else
        git svn $cloneopts clone $TYPE "${SVNURL}/${SVNROOT}/${SVNDIR}" .
    fi
    if [[ $? -ne 0 ]] ; then errorStr "'git-svn' process failed"; fi

    # local settings
    if [ -n "$GIT_USER_NAME" ]; then
        git config user.name "$GIT_USER_NAME"
    fi
    if [ -n "$GIT_USER_EMAIL" ]; then
        git config user.email "$GIT_USER_EMAIL"
    fi

    # deleting any git-svn remote branch
    for SVNSTUFF in `git branch -r | grep 'git-svn'`; do
        echo "- deleting '$SVNSTUFF'"
        git branch -r -D "${SVNSTUFF}";
    done
    if [[ $? -ne 0 ]] ; then errorStr "'git-branch' process failed"; fi

    # rearrange tags and branches
    local REMOTESPREFIX="remotes/"
    if [ -n "$SVN_PREFIX" ]; then
        REMOTESPREFIX+="${SVN_PREFIX}"
    fi
    if [ -n "$BRANCHES_RECOVERY" ]; then
        echo "recovery of original branches ..."
        for BRANCH in $(eval "$BRANCHES_RECOVERY"); do
            echo "- getting '$BRANCH'"
            git branch $BRANCH "${REMOTESPREFIX}${BRANCH}";
        done
    fi
    if [[ $? -ne 0 ]] ; then errorStr "'git-branch' process failed"; fi
    if [ -n "$TAGS_RECOVERY" ]; then
        echo "recovery of original tags ..."
        for TAG in $(eval "$TAGS_RECOVERY"); do
            echo "- getting '$TAG'"
            git tag -a -m "Converting SVN tags" $TAG "${REMOTESPREFIX}tags/${TAG}";
        done
    fi
    if [[ $? -ne 0 ]] ; then errorStr "'git-tag' process failed"; fi
    if $DELETE_SVN_REMOTES; then
        echo "deleting original svn remotes ..."
        if [ -n "$SVN_PREFIX" ]; then
            for SVNSTUFF in $(eval "git branch -r | grep '${SVN_PREFIX}'"); do
                echo "- deleting '$SVNSTUFF'"
                git branch -r -D "${SVNSTUFF}";
            done
        else
            for SVNSTUFF in `git branch -r | grep 'trunk'`; do
                echo "- deleting '$SVNSTUFF'"
                git branch -r -D "${SVNSTUFF}";
            done
        fi
        if [[ $? -ne 0 ]] ; then errorStr "'git-branch' process failed"; fi
        git config --remove-section svn-remote.svn
        git config --remove-section svn
    fi

    # clean-up
    cleanUp
    if ! $KEEP_AUTHORSFILE; then
        if [ -f $GITAUTHORS_FILENAME ]; then
            rm -f $GITAUTHORS_FILENAME
            git config --unset svn.authorsfile
        fi
    fi
    if ! $KEEP_IGNOREFILE; then
        if [ -f $GITIGNORE_FILENAME ]; then
            rm -f $GITIGNORE_FILENAME
        fi
    fi
    git add --all && git commit -m "Automatic cleaning process";
    if [[ $? -ne 0 ]] ; then errorStr "'git-commit' process failed"; fi

    # rewrite all authors and commiters and hide tricky infos in messages
    local gitfilteropts="--tag-name-filter cat"
    if [ -n "$MSG_GITFILTER" ]; then
        gitfilteropts+=" --msg-filter \"$MSG_GITFILTER\""
    fi
    if [ -n "$ENV_GITFILTER" ]; then
        gitfilteropts+=" --env-filter \"$ENV_GITFILTER\""
    fi
    eval "git filter-branch -f $gitfilteropts -- --all;"
    if [[ $? -ne 0 ]] ; then errorStr "'git-filter-branch' process failed"; fi

    # new svn-back branch to store dependences
    if [ -n "$BACKUP_DIRS" ]; then
        local LOCAL_DIRS=(${BACKUP_DIRS//,/ })
        echo "getting back distant directories '${LOCAL_DIRS[@]}' in branch '$SVN_BRANCH'"
        git branch $SVN_BRANCH && git checkout $SVN_BRANCH
        if [[ $? -ne 0 ]] ; then errorStr "'git-branch' process failed"; fi
        for LOCAL_DIR in "${LOCAL_DIRS[@]}"; do
            svn checkout "${SVNURL}/${SVNROOT}/${SVNDIR}/${LOCAL_DIR}" $LOCAL_DIR
        done
        if [[ $? -ne 0 ]] ; then errorStr "'svn-checkout' process failed"; fi
        cleanUp
        git add --all && git commit -m "Backup of SVN original dependencies";
        if [[ $? -ne 0 ]] ; then errorStr "'git-commit' process failed"; fi
        git checkout master
    fi

    # pre server hook
    if [ -n "$PRE_SERVER_HOOK" ]; then
        echo "executing pre-server-hook: $PRE_SERVER_HOOK"
        eval "$PRE_SERVER_HOOK"
    fi
    if [[ $? -ne 0 ]] ; then errorStr "'per-server-hook' process failed"; fi

    # cleaning new repo
    git checkout master;
    git gc --aggressive --prune=now;

    # if not in test mode
    if ! $_TESTMODE; then
        # if server is defined
        if [ -n "$SERVER" ]; then
            # clean existing
            if $_SERVERCLEANMODE; then
                echo "removing existant copy on '$SERVER'"
                if $IS_SSH_SERVER; then
                    ssh $SERVER "rm -rf '${GITROOT}/${GITDIR}.git'";
                    if [[ $? -ne 0 ]] ; then errorStr "'ssh' process failed"; fi
                else
                    rm -rf "${SERVER}/${GITROOT}/${GITDIR}.git";
                    if [[ $? -ne 0 ]] ; then errorStr "local server process failed"; fi
                fi
            fi
        
            # create the server bare repository
            echo "creating copy to '$SERVER'"
            if $IS_SSH_SERVER; then
                ssh $SERVER "mkdir '${GITROOT}/${GITDIR}.git' && cd '${GITROOT}/${GITDIR}.git' && git init --bare";
                if [[ $? -ne 0 ]] ; then errorStr "'ssh' process failed"; fi
            else
                oldpwd=`pwd`
                mkdir "${SERVER}/${GITROOT}/${GITDIR}.git" && cd "${SERVER}/${GITROOT}/${GITDIR}.git" && git init --bare;
                if [[ $? -ne 0 ]] ; then errorStr "local server process failed"; fi
                cd $oldpwd
            fi
        else
            echo "!! > no distant server defined";
        fi;

        # set up remote
        git remote add origin "${GITURL}/${GITROOT}/${GITDIR}.git";
        if [ ! -n "$(git config branch.master.remote)" ]; then
            git config branch.master.remote origin
            git config branch.master.merge refs/heads/master
        fi

        # clean-up GIT and push all stuff
        echo "pushing copy to '$SERVER'"
        git push --force --all && git push --tags;
        if [[ $? -ne 0 ]] ; then
            git push -u origin master;
            git push --force --all && git push --tags;
            if [[ $? -ne 0 ]] ; then errorStr "'git-push' process failed"; fi
        fi
    fi
    return 0
}

###################### process

if [ "$#" -eq 0 ]; then
    errorStr "nothing to do (argument required)"
fi
if [ -n "$1" ]; then
    if [ "$1" = '-h' -o "$1" = '--help' -o "$1" = 'help' ]; then
        help; exit 0;
    elif [ "$1" = '-i' -o "$1" = '--usage' -o "$1" = 'usage' ]; then
        usage; exit 0;
    fi
fi

# options
SCRIPTOPTS=""
for var in "$@"; do
    case "$var" in
        -V)
            echo "$VERSION"
            exit 0
            ;;
        debug|--debug|-x)
            export _DEBUG=true; shift
            ;;
        verbose|--verbose|-v)
            export _VERBOSE=true; shift
            ;;
        quiet|--quiet|-q)
            export _QUIET=true; shift
            ;;
        --dry-run)
            export _DRYRUN=true; shift
            SCRIPTOPTS+="dry-run "
            ;;
        --clean)
            export _LOCALCLEANMODE=true; shift
            SCRIPTOPTS+="clean "
            ;;
        --server-clean)
            export _SERVERCLEANMODE=true; shift
            SCRIPTOPTS+="server-clean "
            ;;
        --test)
            export _TESTMODE=true; shift
            SCRIPTOPTS+="test "
            ;;
    esac
done

LOCAL_NAME="$1"
SVN_NAME="${2:-${LOCAL_NAME}}"
if [ "$SVN_NAME" = '-' ]; then SVN_NAME="${LOCAL_NAME}"; fi
GIT_NAME="${3:-${LOCAL_NAME}}"
if [ "$GIT_NAME" = '-' ]; then GIT_NAME="${LOCAL_NAME}"; fi
if [ "$GIT_NAME" = 'svn_name' ]; then GIT_NAME="${SVN_NAME}"; fi
TYPE="${4:-none}"
if [ "$TYPE" = '-' ]; then TYPE='none'; fi
BACKUP_DIRS="${5}"
if [ "$BACKUP_DIRS" = '-' ]; then BACKUP_DIRS=""; fi
PRE_SERVER_HOOK="${6}"

export BASE_DIR=$(stripTrailingSlash "$BASE_DIR")
export SVNURL=$(stripTrailingSlash "$SVNURL")
export SVNROOT=$(stripTrailingSlash "$SVNROOT")
export GITURL=$(stripTrailingSlash "$GITURL")
export GITROOT=$(stripTrailingSlash "$GITROOT")
export SERVER=$(stripTrailingSlash "$SERVER")
export LOCAL_NAME SVN_NAME GIT_NAME TYPE PRE_SERVER_HOOK BACKUP_DIRS

# debug
if $_DEBUG; then debug "$*"; exit 0; fi

# errors
if [ ! -n "$LOCAL_NAME" ]; then errorStr "'local_name' is empty"; fi
if [ ! -n "$(which git)" ]; then errorStr "'git' command not found - you must install GIT (<http://git-scm.com/>)"; fi
if [ ! -n "$(which svn)" ]; then errorStr "'svn' command not found - you must install SVN (<http://subversion.apache.org/>)"; fi

# process
if [ "$SCRIPTOPTS" != '' ]; then SCRIPTOPTS="[${SCRIPTOPTS}] "; fi
if $_DRYRUN; then
    echo "${SCRIPTOPTS}-- > would process: processSvnToGit $LOCAL_NAME $SVN_NAME $GIT_NAME $TYPE \"$BACKUP_DIRS\" \"$PRE_SERVER_HOOK\""
    echo "----"
    exit 0
else
    echo "${SCRIPTOPTS}-- > processing 'processSvnToGit $LOCAL_NAME $SVN_NAME $GIT_NAME $TYPE \"$BACKUP_DIRS\" \"$PRE_SERVER_HOOK\"'"
    processSvnToGit && cd $HERE
    echo "_ ok"
fi

exit 0
# Endfile