#!/usr/bin/env bash
#
# http://www.commandlinefu.com/commands/view/9379/copy-your-ssh-public-key-to-a-server-from-a-machine-that-doesnt-have-ssh-copy-id
#

#######################################################################
# script infos
VERSION="0.0.1-dev"
NAME="ssh-copy-id (alt)"
PRESENTATION="This script is an alternative to the 'ssh-copy-id' command."
USAGE="usage:  ${0} <ssh-host> <ssh-key>"

# library dir
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# usage ()
usage () {
    echo "## ${NAME} - ${VERSION} ##"
    echo "${PRESENTATION}"
    echo 
    echo "${USAGE}"
    echo 
}
# error ( str='' )
error () {
    [ $# -ne 0 ] && echo -e ">> $*\n";
    usage; exit 1;
}
#######################################################################

[ $# -eq 0 ] && error 'missing argument!';
if [ "$1" == '-h' ]||[ "$1" == '--help' ]||[ "$1" == 'help' ]; then error; fi

SSHOME=~/.ssh/
REMOTE="$1"

if [ $# -gt 1 ]; then
    SSHKEY="$2"
else
    echo "> Select the key to transfer:"
    select item in $(ls ~/.ssh/*.pub); do
        if [ -f ${item} ]; then
            SSHKEY=$item
            break
        fi
    done
fi

cat ${SSHKEY} | \
    ssh "$REMOTE" "(
        cat > tmp.pubkey ; 
        mkdir -p .ssh ; 
        touch .ssh/authorized_keys ; 
        sed -i.bak -e '/$(awk '{print $NF}' ${SSHKEY})/d' .ssh/authorized_keys;  
        cat tmp.pubkey >> .ssh/authorized_keys; 
        rm tmp.pubkey
    )";

exit 0
# Endfile
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=sh
