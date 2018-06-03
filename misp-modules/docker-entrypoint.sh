#!/bin/bash

: ${LISTEN_ADDR:=0.0.0.0}
: ${LISTEN_PORT:=6666}
: ${REDIS_HOST:=redis}
: ${REDIS_PORT:=6379}

echo 'Applying settings from environment vars'
sed -i -e "s;^hostname = .*$;hostname = '$REDIS_HOST';" /usr/local/src/misp-modules/misp_modules/helpers/cache.py
sed -i -e "s;^port = .*$;port = $REDIS_PORT;" /usr/local/src/misp-modules/misp_modules/helpers/cache.py

while true; do
    ping=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping 2> /dev/null)
    sleep 1
    [[ $ping = 'PONG' ]] && break
    echo 'Waiting for redis to come up...'
done

exec /usr/local/bin/misp-modules -l $LISTEN_ADDR -p $LISTEN_PORT