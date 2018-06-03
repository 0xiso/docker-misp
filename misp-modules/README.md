# MISP Docker image

Run MISP modules inside Docker.

## Supported tags

You can use following tags on Docker hub:

* `latest` - latest commit from the master branch

## How to use this image

1. Start Redis server if you have not.

```
$ docker run --name some-redis -d redis:alpine
```

2. Run the MISP modules image.

```
$ docker run \
    --name misp-modues \
    --link some-redis:redis \
    -d 0xiso/misp-modules
```

3. Run the MISP image and link to the MISP modules container.

## Environment variables summary

The following environment variables are honored for configuring your MISP instance:

* `LISTEN_ADDR` - defaults to "0.0.0.0"
* `LISTEN_PORT` - defaults to "6666"
* `REDIS_HOST` - defaults to "redis"
* `REDIS_PORT` - defaults to "6379"

Please report any issues with the Docker image to https://github.com/0xiso/docker-misp/issues
