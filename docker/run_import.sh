#!/bin/sh
# Runs a task script written for Open Server Panel inside the container.
# The scripts read and write files in c:/ospanel/userdata/temp/upload/, the container
# has the same folder mounted as /var/lib/mysql-files, so only the path is replaced.
# Usage (from docker-entrypoint-initdb.d): run_import.sh /scripts/9.1_import.sql
sed "s#c:/ospanel/userdata/temp/upload/#/var/lib/mysql-files/#g" "${1:-/scripts/9.1_import.sql}" | mysql -uroot -p"$MYSQL_ROOT_PASSWORD"
