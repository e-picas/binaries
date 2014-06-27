#!/bin/bash
#
# synch-ssh-root.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Add the BOM marker at the top of a file
#

if [ $# -eq 0 ]; then
    echo "> missing arg!"
    echo "usage: $0 <working_dir/file> [<mask=*.php>]"
    exit 1
fi

_DIR="$1"
_MASK="${2:-*.php}"

for _f in `find "${_DIR}" -type f -name "${_MASK}"`; do
    echo ${_f}
    _f_tmp=${_f}.tmp
    printf '\xEF\xBB\xBF' > ${_f_tmp}
    cat ${_f} >> ${_f_tmp} 
    rm -f ${_f} && mv ${_f_tmp} ${_f}
done

exit 0
# Endfile
