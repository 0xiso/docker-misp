FROM debian:stretch-slim

RUN set -ex \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends \
		git \
		curl \
		python3 \
		libpython3.5-dev \
		redis-tools \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/* \		
	&& curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
	&& python3 get-pip.py --no-cache-dir \
	&& rm -fr get-pip.py

RUN git clone https://github.com/MISP/misp-modules.git /usr/local/src/misp-modules \
	&& cd /usr/local/src/misp-modules \
	&& pip3 install -I -r REQUIREMENTS \
	&& pip3 install -I . \
	&& ln -s /usr/local/lib/python3.5/dist-packages/usr/lib/libyara.so /usr/lib/libyara.so

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

COPY docker-entrypoint.sh /

EXPOSE 6666
CMD ["/docker-entrypoint.sh"]
