#!/bin/bash
#
# duplicate-file.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Duplicate a file or dir
#

if [ ! -z "$1" ]; then
    if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
        echo
        echo "## File duplicator ##"
        echo "This script creates a copy of input file in the same directory, naming it 'ORIGINAL_NAME.copy.EXT'."
        echo
        echo "# Usage:"
        echo "        ~$ sh $0 [options] file-path target-name"
        echo
        echo "# Options:"
        echo "        file-path        absolute path of the file to copy"
        echo "        target-path      absolute path or file name of the copy (default is 'ORIGINAL_NAME.copy.EXT' in the original directory)"
        echo "        -h | --help      usage info"
        echo
        echo "##"
        echo
        exit 0
    fi
fi

if [ -z $1 ]; then
    echo "You must precise the file to work on ..."
    exit 1
fi
SOURCEFILE=$1
SOURCEFILE_FILENAME=$(basename "$SOURCEFILE")
SOURCEFILE_EXTENSION="${SOURCEFILE_FILENAME##*.}"
SOURCEFILE_NAME="${SOURCEFILE_FILENAME%.*}"

if [ ! -f $SOURCEFILE ]; then
    echo "File '$SOURCEFILE' can not be found ..."
    exit 1
fi

TARGET_MASK="%s.copy.%s"
if [ ! -z $2 ]; then
    TARGET_MASK=$2
fi
TARGET_FILENAME=$(printf "$TARGET_MASK" "$SOURCEFILE_NAME" "$SOURCEFILE_EXTENSION")

cp $SOURCEFILE $TARGET_FILENAME && echo $TARGET_FILENAME || echo "error while copying '$SOURCEFILE' to '$TARGET_FILENAME'"
exit 0
