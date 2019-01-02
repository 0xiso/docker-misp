#!/bin/bash

: ${MYSQL_DB_HOST:=mysql}
: ${MYSQL_DB_PORT:=3306}
: ${MYSQL_DB_USER:=root}
: ${MYSQL_DB_PASSWORD:=password}
: ${REDIS_HOST:=redis}
: ${REDIS_PORT:=6379}
: ${MISP_MODULES_HOST:=http://misp-modules}
: ${MISP_MODULES_PORT:=6666}


echo 'Applying settings from environment vars'

sed -i -e "s;'host' => .*,;'host' => '$MYSQL_DB_HOST',;" /var/www/MISP/app/Config/database.php
sed -i -e "s;'port' => .*,;'port' => $MYSQL_DB_PORT,;" /var/www/MISP/app/Config/database.php
sed -i -e "s;'login' => .*,;'login' => '$MYSQL_DB_USER',;" /var/www/MISP/app/Config/database.php
# sed -i -e "s;'encoding' => 'utf8',;'encoding' => 'utf8mb4',;" /var/www/MISP/app/Config/database.php
sed -i -e "s;'password' => .*,;'password' => '$MYSQL_DB_PASSWORD',;" /var/www/MISP/app/Config/database.php
sed -i -e "s;'host' => .*,;'host' => '$REDIS_HOST',;" /var/www/MISP/app/Plugin/CakeResque/Config/config.php
sed -i -e "s;'port' => .*,;'port' => '$REDIS_PORT',;" /var/www/MISP/app/Plugin/CakeResque/Config/config.php

while ! mysqladmin ping -h "$MYSQL_DB_HOST" -P "$MYSQL_DB_PORT" --silent; do
    echo 'Waiting for DB to come up...'
    sleep 1
done

if [[ $(mysql -N -s -u "$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -h "$MYSQL_DB_HOST" -P "$MYSQL_DB_PORT" -e "select count(*) from information_schema.tables where table_schema='misp';") == 0 ]]; then
    echo 'Creating misp database'
    mysql -u "$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -h "$MYSQL_DB_HOST" -P "$MYSQL_DB_PORT" -e "create database misp;"
fi

if [[ $(mysql -N -s -u "$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -h "$MYSQL_DB_HOST" -P "$MYSQL_DB_PORT" -e "select count(*) from information_schema.tables where table_schema='misp' and table_name='admin_settings';") == 0 ]]; then
    echo 'Initializing table'
    # cat /var/www/MISP/INSTALL/MYSQL.sql | sed -e 's/utf8/utf8mb4/g' | mysql -u "$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -h "$MYSQL_DB_HOST" -P "$MYSQL_DB_PORT" misp
    mysql -u "$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -h "$MYSQL_DB_HOST" -P "$MYSQL_DB_PORT" misp < /var/www/MISP/INSTALL/MYSQL.sql
fi


set_config() {
    /var/www/MISP/app/Console/cake Admin setSetting "$1" "$2" --quiet
}

set_config "MISP.python_bin" "/var/www/MISP/venv/bin/python"
set_config "Plugin.ZeroMQ_redis_host" "$REDIS_HOST"
set_config "Plugin.ZeroMQ_redis_port" "$REDIS_PORT"
set_config "MISP.redis_host" "$REDIS_HOST"
set_config "MISP.redis_port" "$REDIS_PORT"

if [ "$MISP_BASEURL" ]; then
    set_config "MISP.baseurl" "$MISP_BASEURL"
fi

if [ "$MISP_DISABLE_EMAILING" ]; then
    set_config "MISP.disable_emailing" true
fi

if [ "$MISP_ATTACHMENTS_DIR" ]; then
    chown -R www-data: "$MISP_ATTACHMENTS_DIR"
    set_config "MISP.attachments_dir" "$MISP_ATTACHMENTS_DIR"
fi

if [ "$MISP_SCHEDULER_WORKER_ENABLE" ]; then
    sed -i -e "s;'enabled' => false,;'enabled' => true,;" /var/www/MISP/app/Plugin/CakeResque/Config/config.php
fi

if [ "$MISP_ENRICHMENT_ENABLE" ]; then
    set_config "Plugin.Enrichment_services_enable" true
    set_config "Plugin.Enrichment_hover_enable" true
    set_config "Plugin.Enrichment_timeout" 300
    set_config "Plugin.Enrichment_hover_timeout" 150
    set_config "Plugin.Enrichment_cve_enabled" true
    set_config "Plugin.Enrichment_dns_enabled" true
    set_config "Plugin.Enrichment_services_url" "$MISP_MODULES_HOST"
    set_config "Plugin.Enrichment_services_port" "$MISP_MODULES_PORT"
fi

if [ "$MISP_IMPORT_ENABLE" ]; then
    set_config "Plugin.Import_services_enable" true
    set_config "Plugin.Import_timeout" 300
    set_config "Plugin.Import_ocr_enabled" true
    set_config "Plugin.Import_csvimport_enabled" true
    set_config "Plugin.Import_services_url" "$MISP_MODULES_HOST"
    set_config "Plugin.Import_services_port" "$MISP_MODULES_PORT"
fi

if [ "$MISP_EXPORT_ENABLE" ]; then
    set_config "Plugin.Export_services_enable" true
    set_config "Plugin.Export_timeout" 300
    set_config "Plugin.Export_pdfexport_enabled" true
    set_config "Plugin.Export_services_url" "$MISP_MODULES_HOST"
    set_config "Plugin.Export_services_port" "$MISP_MODULES_PORT"
fi

if [ "$MISP_ZEROMQ_ENABLE" ]; then
    set_config "Plugin.ZeroMQ_enable" true
    set_config "Plugin.ZeroMQ_event_notifications_enable" true
    set_config "Plugin.ZeroMQ_object_notifications_enable" true
    set_config "Plugin.ZeroMQ_object_reference_notifications_enable" true
    set_config "Plugin.ZeroMQ_attribute_notifications_enable" true
    set_config "Plugin.ZeroMQ_tag_notifications_enable" true
    set_config "Plugin.ZeroMQ_sighting_notifications_enable" true
    set_config "Plugin.ZeroMQ_user_notifications_enable" true
    set_config "Plugin.ZeroMQ_organisation_notifications_enable" true
fi

if [ "$MISP_FIX_PERMISSION" ]; then
    echo 'Fixing permissions. This may take a while.'
    find /var/www/MISP ! \( -type d -name venv -prune \) ! \( -user www-data -group www-data \) -exec chown www-data:www-data {} +
    find /var/www/MISP ! \( -type d -name venv -prune \) ! -perm 750 -exec chmod 750 {} +
    find /var/www/MISP/app/tmp ! -perm 2770 -exec chmod 2770 {} +
    find /var/www/MISP/app/files ! -perm 2770 -exec chmod 2770 {} +
    find /var/www/MISP/app/files/scripts/tmp ! -perm 2770 -exec chmod 2770 {} +
fi

if [ "$MISP_LIVE" ]; then
    /var/www/MISP/app/Console/cake Live 1 --quiet
fi

rm -fr /var/www/MISP/app/files/scripts/mispzmq/mispzmq.pid
exec /venv/bin/circusd /circus.ini