#!/bin/bash

if [ ! -e web/app.php ]; then
    if [ "$(id -u)" = '0' ] && [ "$(stat -c '%u:%g' .)" = '0:0' ]; then
        chown "www-data:www-data" .
    fi
    echo >&2 "LabDB not found in $PWD - copying now..."
		if [ -n "$(ls -A)" ]; then
		    echo >&2 "WARNING: $PWD is not empty! (copying anyhow)"
		fi
    sourceTarArgs=(
			--create
			--file -
			--directory /usr/src/LabDB
			--owner "www-data" --group "www-data"
		)
		targetTarArgs=(
			--extract
			--file -
		)
		if [ "$user" != '0' ]; then
			targetTarArgs+=( --no-overwrite-dir )
		fi
		tar "${sourceTarArgs[@]}" . | tar "${targetTarArgs[@]}"
    echo >&2 "Complete! WordPress has been successfully copied to $PWD"
fi

# Configure the application
sed -i "s/database_driver: pdo_mysql/database_driver: ${DB_DRIVER}/" app/config/parameters.yml
sed -i "s/database_host: localhost/database_host: ${DB_HOST}/" app/config/parameters.yml
sed -i "s/database_port: 3306/database_port: ${DB_PORT}/" app/config/parameters.yml
sed -i "s/database_name: labdb/database_name: ${DB_NAME}/" app/config/parameters.yml
sed -i "s/database_user: root/database_user: ${DB_USER}/" app/config/parameters.yml
sed -i "s/database_password: null/database_password: ${DB_PASSWORD}/" app/config/parameters.yml
sed -i "s/cache_driver: redis/cache_driver: ${CACHE_DRIVER}/" app/config/parameters.yml
sed -i "s/cache_host: localhost/cache_host: ${CACHE_HOST}/" app/config/parameters.yml
sed -i "s/cache_port: 6379/cache_port: ${CACHE_PORT}/" app/config/parameters.yml
sed -i "s/print_host: null/print_host: ${PRINT_HOST}/" app/config/parameters.yml
sed -i "s/print_queue: null/print_queue: ${PRINT_QUEUE}/" app/config/parameters.yml

TERM=dumb php -- <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)
$stderr = fopen('php://stderr', 'w');
$driver = str_replace('pdo_', '', getenv('DB_DRIVER'));
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');
$rootPass = getenv('DB_ROOT_PASSWORD');
$db = getenv('DB_NAME');

try {
    $dbh = new PDO("$driver:host=$host", root, $rootPass);

    $dbh->exec("CREATE DATABASE IF NOT EXISTS `$db`;
                CREATE USER '$user'@'%' IDENTIFIED BY '$pass';
                GRANT ALL ON `$db`.* TO '$user'@'%';
                FLUSH PRIVILEGES;")
        or die(print_r($dbh->errorInfo(), true));

} catch (PDOException $e) {
    die("DB ERROR: ". $e->getMessage());
}

EOPHP

TERM=dumb php -- <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)
$stderr = fopen('php://stderr', 'w');
$driver = str_replace('pdo_', '', getenv('DB_DRIVER'));
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASSWORD');
$rootPass = getenv('DB_ROOT_PASSWORD');
$db = getenv('DB_NAME');

try {
    $dbh = new PDO("$driver:host=$host;dbname=$db", $user, $pass);

    $dbh->exec("SELECT id FROM Vial LIMIT 1;")
        or die($dbh->errorInfo()[1]);

} catch (PDOException $e) {
    die("DB ERROR: ". $e->getMessage());
}

EOPHP
if [ $? != 0  ]; then
  su www-data -s /bin/bash -c 'bin/console doctrine:schema:create --env=prod'
fi

if [ ! -d web/bundles ]; then
    su www-data -s /bin/bash -c 'bin/console assets:install --env=prod'
fi

if [ ! -d web/css ] || [ ! -d web/font ] || [ ! -d web/js ]; then
  su www-data -s /bin/bash -c 'bin/console assetic:dump --env=prod'
fi

su www-data -s /bin/bash -c 'bin/console cache:clear --env=prod'

set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

echo "$@"

exec "$@"
