#!/bin/bash

set -eux

if [[ ! -f /app/data/config.yml ]]; then
    echo "=> Detected first run"

    # set up default directories with write access and copy the data from readonly
    cp /app/code/config/config.example.yml /app/data/config.yml
    cp /app/code/.htaccess_orig /app/data/htaccess

    # update config with ffmpeg and audio conversion
    sed -i "s,convert:.*,convert: true," /app/data/config.yml
    sed -i "s,avconv:.*,avconv: /usr/bin/ffmpeg," /app/data/config.yml
    sed -i "s,audioBitrate:.*,audioBitrate: 256," /app/data/config.yml
    sed -i "s,stream:.*,stream: true," /app/data/config.yml

    echo -e "\nremux: true" >> /app/data/config.yml
fi

if [[ ! -d /tmp/templates_c/ ]]; then
    mkdir /tmp/templates_c/
fi

if [[ ! -d /tmp/sessions/ ]]; then
    mkdir /tmp/sessions/
fi


echo "=> Ensuring runtime directories"
chown -R www-data.www-data /app/data /run /tmp

echo "=> Run alltube"
APACHE_CONFDIR="" source /etc/apache2/envvars
rm -f "${APACHE_PID_FILE}"
exec /usr/sbin/apache2 -DFOREGROUND
