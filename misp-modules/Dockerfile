FROM python:3-slim

RUN set -ex \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    gcc \
    git \
    libc6-dev \
    redis-tools \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/src/misp-modules
RUN set -ex \
  && git clone https://github.com/MISP/misp-modules.git . \
  && python3 -m venv venv \
  && venv/bin/pip install -I -r REQUIREMENTS \
  && venv/bin/pip install -e .
  
COPY docker-entrypoint.sh /

EXPOSE 6666
CMD ["/docker-entrypoint.sh"]