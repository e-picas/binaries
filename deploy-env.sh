#!/usr/bin/env bash
#
# deploy-env.sh
# by @picas (me at picas dot fr)
# <http://github.com/e-picas/binaries.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Link "*_ENV" files
#
set -e

# usage
if [ -z "$1" ]; then
    {   echo "usage: $0 <env> [dir=PWD]"
        echo "  e.g. $0 PROD"
    } >&2
    exit 1
fi

# deployement
ENV=$(echo "${1:-prod}" | tr '[:lower:]' '[:upper:]')
ROOT_DIR="${2:-$(pwd)}"
for f in $(find . -name "*_${ENV}"); do
    fn=$(basename $f)
    d=$(dirname $f)
    echo "$f > ${fn/_${ENV}/}"
    ( cd $d && ln -fs $fn "${fn/_${ENV}/}" )
done

# vim: autoindent expandtab tabstop=4 shiftwidth=4 softtabstop=4 filetype=sh
