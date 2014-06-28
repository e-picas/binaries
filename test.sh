#!/bin/bash

export GIT_USER_NAME="Piero Wbmstr"
export GIT_USER_EMAIL="me@e-piwi.fr"
export SVNURL="file:///opt/local/www/repositories/"
export SVNROOT="svn/"
export GITURL="/opt/local/www/"
export GITROOT="temp/"
export SERVER="/opt/local/www/"
export GITIGNORE_FILEPATH="`pwd`/.gitignore"
export KEEP_IGNOREFILE=true
export DELETE_SVN_REMOTES=false

SVNTOGIT="svn-to-git.sh"
SVNTOGITOPTS="$*"
if [ ! -f $SVNTOGIT ]; then
    echo "!! script '$SVNTOGIT' can not be found (searched in current working directory)"
    exit 1
fi

sh $SVNTOGIT $SVNTOGITOPTS mytest test-svn-to-git - classic - " \
    cp phpinfo.php phpinfo_bis.php; \
    git add --all && git commit -m 'Automatic duplication by hook'; \
";

exit 0