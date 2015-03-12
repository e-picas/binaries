#!/bin/bash
#
# add-bom.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Add the BOM marker at the top of a file or dir contents
#

usage () {
    echo "usage: $0 <dir/file> [<mask=*.php>] [<target_filename=%s>]"
}

processOneFile () {
    local FILESOURCE="${1}"
    if [ "${FILESOURCE}" == "${FILETARGET}" ]||[ '%s' == "${FILETARGET}" ]
    then
        TMPFILE="${FILETARGET}.tmp"
        printf '\xEF\xBB\xBF' > "${TMPFILE}"
        cat "${FILESOURCE}" >> "${TMPFILE}"
        rm -f "${FILESOURCE}" && mv "${TMPFILE}" "${FILETARGET}"
        echo "${FILETARGET} `file -bi "${FILETARGET}"`"
    else
        printf '\xEF\xBB\xBF' > "${FILETARGET}"
        cat "${FILESOURCE}" >> "${FILETARGET}"
        echo "${FILETARGET} `file -bi "${FILETARGET}"`"
    fi
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

if [ "${1}" == '-h' ]||[ "${1}" == '--help' ]
then
    usage
    exit 0
fi

FILESOURCE="${1}"
FILEMASK="${2:-*.php}"
FILETARGET="${3:-%s}"

if [ -f "$FILESOURCE" ]; then
    processOneFile "${FILESOURCE}"

elif [ -d "$FILESOURCE" ]
    for _f in `find "${FILESOURCE}" -type f -name "${FILEMASK}"`; do
        processOneFile "${_f}"
    done

else
    echo "path '${FILESOURCE}' not found!"
    exit 1
fi

exit 0
# Endfile
