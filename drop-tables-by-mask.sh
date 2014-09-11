#!/bin/bash
#
# drop-tables-by-mask.sh
# by @pierowbmstr (me at e-piwi dot fr)
# <http://github.com/piwi/binaires.git>
# (personal) file licensed under CC BY-NC-SA 4.0 <http://creativecommons.org/licenses/by-nc-sa/4.0/>
#
# Drop all tables matching given mask from a MySQL DB
#

usage () {
    echo "usage: $0 <db_name> <mask>"
}

if [ $# -lt 2 ]; then
    echo "> missing arguments !"
    usage
    exit 1
fi

DBNAME=$1
MASK=$2

TMPF=$(mktemp)

echo "usage of temporary file ${TMPF}"

echo "SET FOREIGN_KEY_CHECKS = 0;" >> $TMPF

echo "SET GROUP_CONCAT_MAX_LEN=100000; \
    select CONCAT('drop table ', GROUP_CONCAT( CONCAT(table_schema, '.', table_name)), ';') from information_schema.tables \
    where table_schema='$DBNAME' and table_name like '$MASK';" \
    | mysql -uroot -N --batch $DBNAME >> $TMPF

echo "SET FOREIGN_KEY_CHECKS = 1;" >> $TMPF

mysql -uroot $DBNAME < $TMPF

#rm -f $TMPF
