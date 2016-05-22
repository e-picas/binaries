#!/bin/bash

case $UNAME in
    Darwin)
        _wapache=$(which apache)
        [ "${_wapache}" != '' ] && sudo "${_wapache}" -k restart;
        _wapache2=$(which apache2)
        [ "${_wapache2}" != '' ] && sudo "${_wapache2}" -k restart;
        _wapachectl=$(which apachectl)
        [ "${_wapachectl}" != '' ] && sudo "${_wapachectl}" -k restart;
        _wmysql=$(which mysql)
        [ "${_wmysql}" != '' ] && sudo "${_wmysql}" restart;
        _wmysqld=$(which mysqld)
        [ "${_wmysqld}" != '' ] && sudo "${_wmysqld}" restart;
        _wmysql5=$(which mysql5)
        [ "${_wmysql5}" != '' ] && sudo "${_wmysql5}" restart;
        _wnginx=$(which nginx)
        [ "${_wnginx}" != '' ] && sudo "${_wnginx}" restart;
        _wvarnish=$(which varnish)
        [ "${_wvarnish}" != '' ] && sudo "${_wvarnish}" restart;
        _wredis=$(which redis)
        [ "${_wredis}" != '' ] && sudo "${_wredis}" restart;
        _wmemcached=$(which memcached)
        [ "${_wmemcached}" != '' ] && sudo "${_wmemcached}" restart;
        _wphpfpm=$(which php-fpm)
        [ "${_wphpfpm}" != '' ] && sudo "${_wphpfpm}" restart;
        _wphp5fpm=$(which php5-fpm)
        [ "${_wphp5fpm}" != '' ] && sudo "${_wphp5fpm}" restart;
        ;;
    *)
        [ -f /etc/init.d/apache ] && sudo /etc/init.d/apache restart;
        [ -f /etc/init.d/apache2 ] && sudo /etc/init.d/apache2 restart;
        [ -f /etc/init.d/mysql ] && sudo /etc/init.d/mysql restart;
        [ -f /etc/init.d/nginx ] && sudo /etc/init.d/nginx restart;
        [ -f /etc/init.d/varnish ] && sudo /etc/init.d/varnish restart;
        [ -f /etc/init.d/redis ] && sudo /etc/init.d/redis restart;
        [ -f /etc/init.d/memcached ] && sudo /etc/init.d/memcached restart;
        [ -f /etc/init.d/php-fpm ] && sudo /etc/init.d/php-fpm restart;
        [ -f /etc/init.d/php5-fpm ] && sudo /etc/init.d/php5-fpm restart;
        ;;
esac
echo "_ ok"

# Endfile
