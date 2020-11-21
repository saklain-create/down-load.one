#!/bin/bash

set -eux

echo "=> Ensure directories"
mkdir -p /run/sessions/ /app/data/templates_c/

if [[ ! -f /app/data/config.yml ]]; then
    echo "=> Detected first run"

    # set up default directories with write access and copy the data from readonly
    cp /app/code/config/config.example.yml /app/data/config.yml
    cp /app/code/.htaccess_orig /app/data/htaccess

    # update config with ffmpeg and audio conversion
    sed -i "s,convert:.*,convert: true," /app/data/config.yml
    sed -i "s,convertAdvanced:.*,convertAdvanced: true," /app/data/config.yml
    sed -i "s,avconv:.*,avconv: /usr/bin/ffmpeg," /app/data/config.yml
    sed -i "s,audioBitrate:.*,audioBitrate: 256," /app/data/config.yml
    sed -i "s,stream:.*,stream: true," /app/data/config.yml
    sed -i "s,remux:.*,remux: true," /app/data/config.yml
    sed -i "s,appName:.*,appName: Cloudron Alltube Download," /app/data/config.yml
fi

if [[ ! -f /app/data/php.ini ]]; then
    echo -e "; Add custom PHP configuration in this file\n; Settings here are merged with the package's built-in php.ini\n\n" > /app/data/php.ini
fi

echo "=> Ensuring permissions"
chown -R www-data.www-data /app/data /run /tmp

echo "=> Run alltube"
APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"
exec /usr/sbin/apache2 -DFOREGROUND
