# MISP Docker image

Run MISP inside Docker. This image does not include MySQL server and Redis server to follow "one process per container" practice.

## Supported tags

You can use following tags on Docker hub:

* `latest` - latest commit from the 2.4 branch

## How to use this image

1. Run MySQL server and Redis server.

```
$ docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=password -d mysql:5
$ docker run --name some-redis -d redis:alpine
```

2. Run the MISP image.

```
$ docker run \
    --name some-misp \
    --link some-mysql:mysql \
    --link some-redis:redis \
    -p 80:80 \
    -d 0xiso/misp
```

3. Access the MISP instance with your favorite web browser. You can login with `admin@admin.test / admin`.

4. (Optional) If you want to run MISP modules, execute the following command.

```
$ docker run --name misp-modules -d 0xiso/misp-modules
```

## Use with docker-compose

You can run MISP, MySQL server and redis at once with `docker-compose`.

```
$ curl -LO https://raw.githubusercontent.com/0xiso/docker-misp/master/docker-compose.yml
$ docker-compose up -d
```

## Environment variables summary

The following environment variables are honored for configuring your MISP instance:

* `MYSQL_DB_HOST` - Defaults to "mysql"
* `MYSQL_DB_PORT` - Defaults to "3306"
* `MYSQL_DB_USER` - Defaults to "root"
* `MYSQL_DB_PASSWORD` - Defaults to "password"
* `REDIS_HOST` - Defaults to "redis"
* `REDIS_PORT` - Defaults to "6379"
* `MISP_BASEURL` - Defaults to empty, non-empty value will set MISP.baseurl to specified value
* `MISP_ATTACHMENTS_DIR` - Defaults to empty, which means MISP will use its default location. Useful for persisting data.
* `MISP_MODULES_HOST` - Defaults to "http://misp-modules"
* `MISP_MODULES_PORT` - Defaults to "6666"
* `MISP_LIVE` - Defaults to false, non-empty value will set MISP.live to true
* `MISP_SCHEDULER_WORKER_ENABLE` - Defaults to disabled, non-empty value will enable scheduler worker
* `MISP_DISABLE_EMAILING` - Defaults to disabled, non-empty value will set MISP.disable_emailing to true
* `MISP_ENRICHMENT_ENABLE` - Defaults to disabled, non-empty value will set Plugin.Enrichment_services_enable and Plugin.Enrichment_hover_enable to true
* `MISP_IMPORT_ENABLE` - Defaults to disabled, non-empty value will set Plugin.Import_services_enable to true
* `MISP_EXPORT_ENABLE` - Defaults to disabled, non-empty value will set Plugin.Export_services_enable to true
* `MISP_ZEROMQ_ENABLE` - Defaults to disabled, non-empty value will set Plugin.ZeroMQ_enable to true

Please report any issues with the Docker image to https://github.com/0xiso/docker-misp/issues