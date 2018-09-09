FROM php:7.2-apache

ENV COMPOSER_ALLOW_SUPERUSER 1
WORKDIR /var/www/MISP

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    git \
    libfuzzy-dev \
    libpython3.5-dev \
    libzip-dev \
    mariadb-client \
    python3 \
    zip \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
  && python3 get-pip.py --no-cache-dir \
  && rm -fr get-pip.py \
  && pip3 install \
    circus \
    git+https://github.com/kbandla/pydeep.git \
    lief \
    maec \
    python-magic \
    redis \
  && a2dismod status \
  && a2enmod rewrite \
  && a2dissite 000-default \
  && { \
    echo "max_execution_time = 300"; \
    echo "memory_limit = 512M"; \
    echo "upload_max_filesize = 50M"; \
    echo "post_max_size = 50M"; \
  } > /usr/local/etc/php/php.ini \
  && docker-php-ext-configure zip --with-libzip \
  && docker-php-ext-install -j$(nproc) pcntl pdo_mysql zip \
  && pecl install redis \
  && docker-php-ext-enable redis \
  && pear channel-update pear.php.net \
  && pear install Crypt_GPG

RUN set -ex \
  && git clone https://github.com/MISP/MISP.git /var/www/MISP \
  && cd /var/www/MISP \
  && git config core.filemode false \
  && git submodule update --init --recursive \
  && git submodule foreach --recursive git config core.filemode false \
  && cd /var/www/MISP/app/files/scripts \
  && git clone https://github.com/CybOXProject/python-cybox.git \
  && git clone https://github.com/STIXProject/python-stix.git \
  && git clone https://github.com/CybOXProject/mixbox.git \
  && cd /var/www/MISP/app/files/scripts/python-cybox \
  && git checkout v2.1.0.17 \
  && pip3 install . \
  && cd /var/www/MISP/app/files/scripts/python-stix \
  && pip3 install . \
  && cd /var/www/MISP/app/files/scripts/mixbox \
  && pip3 install . \
  && cd /var/www/MISP/PyMISP \
  && pip3 install . \
  && cd /var/www/MISP/app \
  && php composer.phar require kamisama/cake-resque:4.1.2 \
  && php composer.phar config vendor-dir Vendor \
  && php composer.phar install \
  && chown -R www-data:www-data /var/www/MISP \
  && chmod -R 750 /var/www/MISP \
  && chmod -R g+ws /var/www/MISP/app/tmp \
  && chmod -R g+ws /var/www/MISP/app/files \
  && chmod -R g+ws /var/www/MISP/app/files/scripts/tmp

RUN set -ex \
  && { \
    echo '#!/bin/sh'; \
    echo ''; \
    echo '/var/www/MISP/app/Console/cake userInit -q'; \
    echo 'AUTH_KEY=$(mysql -u "$MYSQL_DB_USER" -p"$MYSQL_DB_PASSWORD" -h "$MYSQL_DB_HOST" -P "$MYSQL_DB_PORT" misp -e "SELECT authkey FROM users;" | tail -1)'; \
    echo 'curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST http://127.0.0.1/galaxies/update'; \
    echo 'curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST http://127.0.0.1/taxonomies/update'; \
    echo 'curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST http://127.0.0.1/warninglists/update'; \
    echo 'curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST http://127.0.0.1/noticelists/update'; \
    echo 'curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST http://127.0.0.1/objectTemplates/update'; \
  } > /initial_update.sh \
  && chmod +x /initial_update.sh

COPY conf/misp.conf /etc/apache2/sites-enabled/
COPY docker-entrypoint.sh /
COPY conf/circus.ini /

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

EXPOSE 80
CMD ["/docker-entrypoint.sh"]
