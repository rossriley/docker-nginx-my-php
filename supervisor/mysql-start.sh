#/bin/sh
DATA_DIR=/data/mysql

# test if DATA_DIR has content
if [ -z "$(ls -A $DATA_DIR)" ]; then
    echo "Initializing Mysql at $DATA_DIR"
    mysql_install_db --user=mysql --datadir=$DATA_DIR

    # These statements _must_ be on individual lines, and _must_ end with
    # semicolons (no line breaks or comments are permitted).
    # TODO proper SQL escaping on ALL the things D:
    TEMP_FILE='/tmp/mysql-first-time.sql'
    cat > "$TEMP_FILE" <<-EOSQL
    DELETE FROM mysql.user ;
    CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
    GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
    DROP DATABASE IF EXISTS test ;
EOSQL
    if [ "$APP_DB" ]; then
        echo "CREATE DATABASE IF NOT EXISTS $APP_DB ;" >> "$TEMP_FILE"
    fi
    if [ "$APP_USER" -a "$APP_PASSWORD" ]; then
        echo "CREATE USER '$APP_USER'@'%' IDENTIFIED BY '$APP_PASSWORD' ;" >> "$TEMP_FILE"
    if [ "$APP_DB" ]; then
        echo "GRANT ALL ON $APP_DB.* TO '$APP_USER'@'%' ;" >> "$TEMP_FILE"
    fi
    echo 'FLUSH PRIVILEGES ;' >> "$TEMP_FILE"
    set -- "$@" --init-file="$TEMP_FILE"

fi

chown -R mysql:mysql $DATA_DIR
chmod -R 700 $DATA_DIR

/etc/init.d/mysql start