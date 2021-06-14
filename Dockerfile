FROM cloudron/base:3.0.0@sha256:455c70428723e3a823198c57472785437eb6eab082e79b3ff04ea584faf46e92

ARG VERSION=3.0.0
ARG YOUTUBEDL_VERSION=2021.06.06

RUN mkdir -p /app/code /app/pkg

WORKDIR /app/code

# get alltube and extract it
RUN curl -L https://github.com/Rudloff/alltube/archive/${VERSION}.tar.gz | tar -xz --strip-components 1 -f - && \
    chown www-data:www-data -R /app/code

# get latest youtube-dl
RUN curl -L https://github.com/ytdl-org/youtube-dl/releases/download/${YOUTUBEDL_VERSION}/youtube-dl -o /usr/local/bin/youtube-dl && \
    chmod +x /usr/local/bin/youtube-dl

RUN sudo -u www-data composer install --no-interaction --optimize-autoloader --no-dev && \
    sudo -u www-data composer clear-cache && \
    mv /app/code/.htaccess /app/code/.htaccess_orig && ln -s /app/data/htaccess /app/code/.htaccess && \
    rm -rf /app/code/templates_c && \
    ln -s /app/data/templates_c /app/code/templates_c && \
    ln -s /app/data/config.yml /app/code/config/config.yml

# install requirements
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    apt-get update && apt-get install -y ffmpeg && rm -rf /var/cache/apt /var/lib/apt/lists

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
COPY apache/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
ADD apache/alltube.conf /etc/apache2/sites-enabled/alltube.conf
RUN echo "Listen 8000" > /etc/apache2/ports.conf

# configure mod_php
RUN a2enmod rewrite mime ldap authnz_ldap proxy_fcgi setenvif
RUN crudini --set /etc/php/7.4/apache2/php.ini PHP upload_max_filesize 128M && \
    crudini --set /etc/php/7.4/apache2/php.ini PHP upload_max_size 128M && \
    crudini --set /etc/php/7.4/apache2/php.ini PHP post_max_size 256M && \
    crudini --set /etc/php/7.4/apache2/php.ini PHP memory_limit 256M && \
    crudini --set /etc/php/7.4/apache2/php.ini PHP max_execution_time 200 && \
    crudini --set /etc/php/7.4/apache2/php.ini Session session.save_path /run/sessions && \
    crudini --set /etc/php/7.4/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/7.4/apache2/php.ini Session session.gc_divisor 100

RUN ln -s /app/data/php.ini /etc/php/7.4/apache2/conf.d/99-cloudron.ini && \
    ln -s /app/data/php.ini /etc/php/7.4/cli/conf.d/99-cloudron.ini

COPY start.sh /app/pkg/

RUN chown -R www-data.www-data /app/code /app/pkg

CMD [ "/app/pkg/start.sh" ]
