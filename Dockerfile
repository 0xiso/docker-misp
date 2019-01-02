FROM php:7.2-apache

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    git \
    libfuzzy-dev \
    libpython3-dev \
    mariadb-client \
    python3 \
    unzip \
    virtualenv \
  && rm -rf /var/lib/apt/lists/* \
  && virtualenv -p python3 /venv \
  && /venv/bin/pip3 install circus \
  && { \
    echo "max_execution_time = 300"; \
    echo "memory_limit = 512M"; \
    echo "upload_max_filesize = 50M"; \
    echo "post_max_size = 50M"; \
  } > /usr/local/etc/php/conf.d/misp.ini \
  && docker-php-ext-install -j$(nproc) pcntl pdo_mysql \
  && pecl install redis \
  && docker-php-ext-enable redis \
  && a2dismod status \
  && a2enmod ssl rewrite headers \
  && a2dissite 000-default \
  && mkdir -p /var/www/MISP \
  && chown www-data: /var/www/MISP

WORKDIR /var/www/MISP
USER www-data

RUN set -ex \
  && git clone https://github.com/MISP/MISP.git . \
  && git config core.filemode false \
  && git submodule update --init --recursive \
  && git submodule foreach --recursive git config core.filemode false \
  && virtualenv -p python3 venv \
  && cd /var/www/MISP/app/files/scripts \
  && git clone https://github.com/CybOXProject/python-cybox.git \
  && git clone https://github.com/STIXProject/python-stix.git \
  && git clone https://github.com/MAECProject/python-maec.git \
  && git clone https://github.com/CybOXProject/mixbox.git \
  && cd /var/www/MISP/app/files/scripts/python-cybox \
  && /var/www/MISP/venv/bin/pip install . \
  && cd /var/www/MISP/app/files/scripts/python-stix \
  && /var/www/MISP/venv/bin/pip install . \
  && cd /var/www/MISP/app/files/scripts/python-maec \
  && /var/www/MISP/venv/bin/pip install . \
  && cd /var/www/MISP/app/files/scripts/mixbox \
  && /var/www/MISP/venv/bin/pip install . \
  && cd /var/www/MISP/PyMISP \
  && /var/www/MISP/venv/bin/pip install . \
  && /var/www/MISP/venv/bin/pip3 install \
    git+https://github.com/kbandla/pydeep.git \
    lief \
    python-magic \
    pyzmq \
    redis \
  && cd /var/www/MISP/app \
  && php composer.phar require kamisama/cake-resque:4.1.2 \
  && php composer.phar config vendor-dir Vendor \
  && php composer.phar install \
  && cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php \
  && cp -a /var/www/MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php \
  && cp -a /var/www/MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php \
  && cp -a /var/www/MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php \
  && cp -a /var/www/MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php

USER root
RUN set -ex \
  && find /var/www/MISP ! \( -type d -name venv -prune \) ! \( -user www-data -group www-data \) -exec chown www-data:www-data {} + \
  && find /var/www/MISP ! \( -type d -name venv -prune \) ! -perm 750 -exec chmod 750 {} + \
  && find /var/www/MISP/app/tmp ! -perm 2770 -exec chmod 2770 {} + \
  && find /var/www/MISP/app/files ! -perm 2770 -exec chmod 2770 {} + \
  && find /var/www/MISP/app/files/scripts/tmp ! -perm 2770 -exec chmod 2770 {} + \
  && rm -fr /tmp/* /root/.cache

COPY conf/misp.conf /etc/apache2/sites-enabled/
COPY docker-entrypoint.sh /
COPY conf/circus.ini /

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

EXPOSE 80
CMD ["/docker-entrypoint.sh"]
