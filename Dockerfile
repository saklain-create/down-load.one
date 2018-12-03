FROM cloudron/base:1.0.0@sha256:147a648a068a2e746644746bbfb42eb7a50d682437cead3c67c933c546357617

ENV ATVERSION=1.2.4

RUN mkdir -p /app/code/ /run/sessions /app/data
WORKDIR /app/code

# get alltube and extract it
RUN wget https://github.com/Rudloff/alltube/releases/download/${ATVERSION}/alltube-${ATVERSION}.zip && \
    unzip alltube-${ATVERSION}.zip && rm alltube-${ATVERSION}.zip && \
    mv /app/code/.htaccess /app/code/.htaccess_orig && \
    rm -rf /app/code/templates_c && \
    ln -s /tmp/templates_c /app/code/templates_c && \
    ln -s /app/data/htaccess /app/code/.htaccess && \
    ln -s /app/data/config.yml /app/code/config/config.yml

# install requirements
RUN apt-get update && apt-get install -y php-fileinfo php-intl php-mbstring php-curl

# install ffmpeg
RUN apt-get install -y ffmpeg && rm -rf /var/cache/apt /var/lib/apt/lists

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
COPY apache/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
ADD apache/alltube.conf /etc/apache2/sites-enabled/alltube.conf
RUN echo "Listen 8000" > /etc/apache2/ports.conf

# configure mod_php
RUN a2enmod rewrite mime
RUN crudini --set /etc/php/7.2/apache2/php.ini PHP upload_max_filesize 128M && \
    crudini --set /etc/php/7.2/apache2/php.ini PHP upload_max_size 128M && \
    crudini --set /etc/php/7.2/apache2/php.ini PHP post_max_size 256M && \
    crudini --set /etc/php/7.2/apache2/php.ini PHP memory_limit 256M && \
    crudini --set /etc/php/7.2/apache2/php.ini PHP max_execution_time 200 && \
    crudini --set /etc/php/7.2/apache2/php.ini Session session.save_path /run/sessions && \
    crudini --set /etc/php/7.2/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/7.2/apache2/php.ini Session session.gc_divisor 100

ADD start.sh /app/

RUN chown -R www-data.www-data /app/code /run/ /tmp /app/data

CMD [ "/app/start.sh" ]
