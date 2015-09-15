#!/bin/bash
#
# getcomposer.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Get the `composer.phar` package
# see <http://getcomposer.org/>
#
set -e

resolve_link() {
    $(type -p greadlink readlink | head -1) "$1"
}

abs_dirname() {
    local cwd="$(pwd)"
    local path="$1"
    while [ -n "$path" ]; do
        cd "${path%/*}"
        local name="${path##*/}"
        path="$(resolve_link "$name" || true)"
    done
    pwd
    cd "$cwd"
}

usage () {
    cat <<MSG
usage:  $0 <prefix> [options]
options:
        --install-dir       : installation directory (default is current)"
        --filename          : installation filename (default is 'composer.phar')"
        --version           : version to install (default is last stable)"
i.e.:   $0 .
        $0 ~/bin wp-cli false
For more info , see <http://getcomposer.org/>.
MSG
}

PREFIX="$(abs_dirname "$1")"
NAME='composer.phar'
ROOT_DIR="$(abs_dirname "$0")"
if [ -z "$1" ]||[ "$1" = '-h' ]||[ "$1" = '--help' ]; then
    usage >&2
    exit 1
fi
shift

cd $PREFIX
if [ $# -gt 0 ]; then
    curl -sS https://getcomposer.org/installer | php -- "$*"
else
    curl -sS https://getcomposer.org/installer | php
fi
if [ -f composer.phar ]; then
    chmod a+x composer.phar
    ln -s composer.phar composer
fi

# End

