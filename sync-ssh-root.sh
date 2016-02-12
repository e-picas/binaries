#!/bin/bash
#
# synch-ssh-root.sh
# by @picas (me at picas dot fr)
# <http://github.com/e-picas/binaries.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Synchronize an SSH config between a user and root on a machine
#

_usrname="${1:-picas}"
ROOT_SSHDIR=/root/.ssh/
USER_SSHDIR=/home/${_usrname}/.ssh/

# sudo 
if [ "`id -u`" != "0" ]; then
    echo "!! > You must run this script as root !";
    exit 1
fi

# let's go

echo "find ${USER_SSHDIR} -exec cp -f {} ${ROOT_SSHDIR} \;"
sudo find ${USER_SSHDIR} -exec cp -f {} ${ROOT_SSHDIR} \;

echo "find ${ROOT_SSHDIR} -regex '.*_\(rsa\|dsa\)' -exec chmod 600 {} \;"
sudo find ${ROOT_SSHDIR} -regex ".*_\(rsa\|dsa\)" -exec chmod 600 {} \;

exit 0

# Endfile
