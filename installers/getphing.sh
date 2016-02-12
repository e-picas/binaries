#!/bin/bash
#
# getphing.sh
# by @picas (me at picas dot fr)
# <http://github.com/e-picas/binaries.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Get the `phing.phar` package
#

if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo
    echo "## PHING installer ##"
    echo "This script will get and install last phing.phar package version."
    echo
    echo "# Usage:"
    echo "        ~$ sh $0 [options]"
    echo
    echo "# Options:"
    echo "        --install-dir     installation directory (default is current)"
    echo "        --filename        installation filename (default is 'phing.phar')"
    echo
    echo "##"
    echo
    exit 0
fi

_TARGETDIR="${1:-.}"
_TARGETFILENAME="${2:-phing.phar}"

curl -L http://www.phing.info/get/phing-latest.phar > "${_TARGETDIR}/${_TARGETFILENAME}"

# End

