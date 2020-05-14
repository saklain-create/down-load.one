FROM cloudron/base:2.0.0@sha256:f9fea80513aa7c92fe2e7bf3978b54c8ac5222f47a9a32a7f8833edf0eb5a4f4

ARG ATVERSION=2.3.0

RUN mkdir -p /app/code /app/pkg /run/sessions /app/data

WORKDIR /app/code

# get alltube and extract it
RUN wget https://github.com/Rudloff/alltube/releases/download/${ATVERSION}/alltube-${ATVERSION}.zip && \
    unzip alltube-${ATVERSION}.zip && rm alltube-${ATVERSION}.zip && \
    mv /app/code/.htaccess /app/code/.htaccess_orig && \
    rm -rf /app/code/templates_c && \
    ln -s /app/data/templates_c /app/code/templates_c && \
    ln -s /app/data/htaccess /app/code/.htaccess && \
    ln -s /app/data/config.yml /app/code/config/config.yml

# install requirements
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/cache/apt /var/lib/apt/lists

# configure apache
RUN rm /etc/apache2/sites-enabled/*
RUN sed -e 's,^ErrorLog.*,ErrorLog "|/bin/cat",' -i /etc/apache2/apache2.conf
COPY apache/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN a2disconf other-vhosts-access-log
COPY apache/alltube.conf.ldap apache/alltube.conf.noldap /app/pkg/
RUN ln -s /run/alltube.conf /etc/apache2/sites-enabled/alltube.conf
RUN echo "Listen 8000" > /etc/apache2/ports.conf

# configure mod_php
RUN a2enmod rewrite mime ldap authnz_ldap proxy_fcgi setenvif
RUN crudini --set /etc/php/7.3/apache2/php.ini PHP upload_max_filesize 128M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP upload_max_size 128M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP post_max_size 256M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP memory_limit 256M && \
    crudini --set /etc/php/7.3/apache2/php.ini PHP max_execution_time 200 && \
    crudini --set /etc/php/7.3/apache2/php.ini Session session.save_path /run/sessions && \
    crudini --set /etc/php/7.3/apache2/php.ini Session session.gc_probability 1 && \
    crudini --set /etc/php/7.3/apache2/php.ini Session session.gc_divisor 100

COPY start.sh /app/

RUN chown -R www-data.www-data /app/code /run/ /tmp /app/data

CMD [ "/app/start.sh" ]
