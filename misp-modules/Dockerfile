FROM debian:stretch-slim

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    libjpeg-dev \
    libpq5 \
    libpython3.5-dev \
    python3 \
    redis-tools \
  && rm -rf /var/lib/apt/lists/* \
  && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
  && python3 get-pip.py --no-cache-dir \
  && rm -fr get-pip.py

RUN git clone https://github.com/MISP/misp-modules.git /usr/local/src/misp-modules \
  && cd /usr/local/src/misp-modules \
  && pip3 install -I -r REQUIREMENTS \
  && ln -s /usr/local/lib/python3.5/dist-packages/usr/lib/libyara.so /usr/lib/libyara.so

COPY docker-entrypoint.sh /

EXPOSE 6666
CMD ["/docker-entrypoint.sh"]
