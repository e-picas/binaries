#!/bin/bash
#
# getwp-cli.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Get the `wp-cli.phar` package
# see <http://wp-cli.org/>
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
usage:  $0 <prefix>
i.e.:   $0 .
        $0 ~/bin
For more info about 'wp-cli.phar', see <http://wp-cli.org/>.
MSG
}

PREFIX="$(abs_dirname "$1")"
NAME='wp-cli.phar'
ROOT_DIR="$(abs_dirname "$0")"
if [ -z "$1" ][ "$1" = '-h' ]||[ "$1" = '--help' ]; then
    usage >&2
    exit 1
fi

# phar itslef
curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > "${PREFIX}/${NAME}"
chmod a+x "${PREFIX}/${NAME}"
echo "> 'wp-cli.phar' installed at '${PREFIX}/${NAME}'"

# bash completion
curl -L https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash > "${PREFIX}/${NAME/.phar/-completion.bash}"
echo "> to use auto-completion, add the following to your .bash_profile:"
echo "    source '${PREFIX}/${NAME/.phar/-completion.bash}'"

# symlink bin
cd $PREFIX
ln -s $NAME "${NAME/.phar/}"
echo "> usage: ${PREFIX}/${NAME/.phar/} --info"

# End
