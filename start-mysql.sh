#!/bin/bash
set -e

VOLUME_HOME="/var/lib/mysql"

# listen on all interfaces
cat > /etc/mysql/conf.d/my.cnf <<EOF
[mysqld]
bind = 0.0.0.0
EOF

# add configuration
cat > /etc/mysql/conf.d/mysqld_charset.cnf <<EOF
[mysqld]
character_set_server=utf8
character_set_filesystem=utf8
collation-server=utf8_general_ci
init-connect='SET NAMES utf8'
init_connect='SET collation_connection = utf8_general_ci'
skip-character-set-client-handshake
EOF

# fix permissions and ownership of /var/lib/mysql
chown -R mysql:mysql $VOLUME_HOME
chmod 700 $VOLUME_HOME

# initialize MySQL data directory
if [ ! -d $VOLUME_HOME/mysql ]; then
        echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
        echo "=> Installing MySQL ..."
        mysql_install_db --user=mysql >/dev/null 2>&1
        echo "=> Done!"

        # start mysql server
        echo "=> Starting MySQL server..."
        /usr/bin/mysqld_safe >/dev/null 2>&1 &
        RET=1
        while [[ RET -ne 0 ]]; do
                echo "=> Waiting for confirmation of MySQL service startup"
                sleep 5
                mysql -uroot -e "status" > /dev/null 2>&1
                RET=$?
        done

        # create root account
        if [ "$MYSQL_PASS" = "**Random**" ]; then
                unset MYSQL_PASS
        fi
        PASS=${MYSQL_PASS:-$(pwgen -s 12 1)}
        _word=$( [ ${MYSQL_PASS} ] && echo "preset" || echo "random" )
        echo "=> Creating MySQL user ${MYSQL_USER} with ${_word} password"

        # grant remote access from '127.0.0.1' address space to root user
        mysql -uroot -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '$PASS'"
        mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION"
        mysql -uroot -e "FLUSH PRIVILEGES"
        echo "=> Done!"
        echo "========================================================================"
        echo "You can now connect to this MySQL Server using:"
        echo ""
        echo "    mysql -u$MYSQL_USER -p$PASS -h<host> -P<port>"
        echo ""
        echo "Please remember to change the above password as soon as possible!"
        echo "MySQL user 'root' has no password but only allows local connections"
        echo "========================================================================"
        mysqladmin -uroot shutdown
else
        echo "=> Using an existing volume of MySQL"
fi

echo "=> Starting MySQL server..."
exec mysqld_safe

echo "=> Reading logs"
tail -F /var/log/mysql/error.log
