#!/usr/bin/env bash
set -e

[ -f /data/params ] && set -a && source /data/params && set +a

: "${MYSQL_HOST:?MYSQL_HOST is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

echo "Waiting for MySQL at ${MYSQL_HOST}..."
until mysqladmin ping -h "$MYSQL_HOST" -uroot -p"$MYSQL_PASSWORD" --silent 2>/dev/null; do
    echo "MySQL not ready, retrying in 2s..."
    sleep 2
done

echo "Running catalogue database setup..."
mysql -h "$MYSQL_HOST" -uroot -p"$MYSQL_PASSWORD" < /db/schema.sql
mysql -h "$MYSQL_HOST" -uroot -p"$MYSQL_PASSWORD" < /db/app-user.sql
mysql -h "$MYSQL_HOST" -uroot -p"$MYSQL_PASSWORD" < /db/master-data.sql
echo "Catalogue database setup complete"
