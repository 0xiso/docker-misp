FROM php:7.2-apache

ENV COMPOSER_ALLOW_SUPERUSER 1
WORKDIR /var/www/MISP

# Setup environment
RUN set -ex \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
		mariadb-client \
		git \
		python \
		libpython2.7-dev \
		python3 \
		libpython3.5-dev \
		unzip \
		supervisor \
		libfuzzy-dev \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
	&& python3 get-pip.py --no-cache-dir \
	&& python2 get-pip.py --no-cache-dir \
	&& rm -fr get-pip.py \
	&& a2dismod status \
	&& a2enmod rewrite \
	&& a2dissite 000-default \
	&& { \
		echo "max_execution_time = 300"; \
		echo "memory_limit = 512M"; \
		echo "upload_max_filesize = 50M"; \
		echo "post_max_size = 50M"; \
	} > /usr/local/etc/php/php.ini \
	&& docker-php-ext-install -j$(nproc) pcntl pdo_mysql \
	&& pecl install redis \
	&& docker-php-ext-enable redis \
	&& pip2 install \
		pymisp \
		git+https://github.com/kbandla/pydeep.git \
		python-magic \
		lief \
		redis \
		pyzmq \
	&& pip3 install \
		pymisp \
		git+https://github.com/kbandla/pydeep.git \
		python-magic \
		lief \
		redis \
		pyzmq

# Install MISP
RUN git clone https://github.com/MISP/MISP.git /var/www/MISP \
	&& cd /var/www/MISP/app/files/scripts \
	&& git clone https://github.com/CybOXProject/python-cybox.git \
	&& git clone https://github.com/STIXProject/python-stix.git \
	&& git clone https://github.com/CybOXProject/mixbox.git \
	&& cd /var/www/MISP/app/files/scripts/python-cybox \
	&& git checkout ce8ff2d6ee5441a85d6a571013b0df60e92dabdb \
	&& pip2 install . \
	&& pip3 install . \
	&& cd /var/www/MISP/app/files/scripts/python-stix \
	&& git checkout v1.2.0.6 \
	&& pip2 install . \
	&& pip3 install . \
	&& cd /var/www/MISP/app/files/scripts/mixbox\
	&& git checkout v1.0.3 \
	&& pip2 install . \
	&& pip3 install . \
	&& cd /var/www/MISP \
	&& git submodule update --init --recursive \
	&& cd /var/www/MISP/app \
	&& php composer.phar require kamisama/cake-resque:4.1.2 \
	&& php composer.phar config vendor-dir Vendor \
	&& php composer.phar install \
	&& git config core.filemode false \
	&& git submodule foreach git config core.filemode false \
	&& chown -R www-data:www-data /var/www/MISP \
	&& chmod -R 750 /var/www/MISP \
	&& chmod -R g+ws /var/www/MISP/app/tmp \
	&& chmod -R g+ws /var/www/MISP/app/files \
	&& chmod -R g+ws /var/www/MISP/app/files/scripts/tmp \
	&& rm -fr /var/www/MISP/app/Plugin/CakeResque/Config/config.php \
	&& rm -fr ~/.composer \
	&& rm -fr ~/.cache

# Avoid `Headers already sent` error (https://github.com/MISP/MISP/pull/3280)
RUN sed -i -e "1s;^\t<?php;<?php;" /var/www/MISP/app/Controller/GalaxiesController.php

COPY conf/misp.conf /etc/apache2/sites-enabled/
COPY docker-entrypoint.sh /
COPY conf/supervisor.conf /etc/supervisor/conf.d/

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

EXPOSE 80
CMD ["/docker-entrypoint.sh"]
