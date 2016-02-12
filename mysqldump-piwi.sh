#!/bin/bash
#
# mysql-dump.sh
# by @picas (me at picas dot fr)
# <http://github.com/e-picas/binaries.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Mysql dump
#

echo ">>> MY mysql dump"

DATE=$(date +%Y%m%d%H%M)

for DB in "$*"
do
    TARGET=/tmp/${DB}_${DATE}.sql
    echo "dumping $DB to $TARGET"
    mysqldump --opt $DB > $TARGET
    gzip $TARGET
done

exit 0
