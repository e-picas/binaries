#!/bin/bash
#
# getcomposer.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Get the `composer.phar` package
#

if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
    echo
    echo "## Composer installer ##"
    echo "This script will get and install last composer.phar package version."
    echo
    echo "# Usage:"
    echo "        ~$ sh $0 [options]"
    echo
    echo "# Options:"
    echo "        --install-dir     installation directory (default is current)"
    echo "        --filename        installation filename (default is 'composer.phar')"
    echo "        --version         version to install (default is last stable)"
    echo
    echo "##"
    echo
    exit 0
fi

if [ $# -gt 0 ]; then
    curl -sS https://getcomposer.org/installer | php -- "$*"
else
    curl -sS https://getcomposer.org/installer | php
fi

# End

