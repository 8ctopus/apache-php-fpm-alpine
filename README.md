# docker apache php-fpm alpine ![Docker Image Size (latest semver)](https://img.shields.io/docker/image-size/8ct8pus/apache-php-fpm-alpine?sort=semver) ![Docker Pulls](https://img.shields.io/docker/pulls/8ct8pus/apache-php-fpm-alpine)

A super light docker web server with Apache and php-fpm on top of Alpine Linux for development purposes

- Apache 2.4.54 with SSL
- php-fpm 8.2.0 RC2, 8.1.10, 8.0.17 or 7.4.21
- Xdebug 3.2.0 alpha 3 - debugger and profiler
- [SPX prolifer 0.4.12](https://github.com/NoiseByNorthwest/php-spx)
- composer 2.4.2
- zsh 5.9
- Alpine 3.16.2

## cool features

- php 8.2, 8.1, 8.0 or 7.4 along with the most commonly used extensions
- Just works with any domain name
- https is configured out of the box
- Apache and php configuration files are exposed on the host for easy edit
- All changes to config files are automatically applied (hot reload)
- Xdebug is configured for step by step debugging and profiling
- Profile php code with SPX or Xdebug

_Note_: On Windows [hot reload doesn't work with WSL 2](https://github.com/microsoft/WSL/issues/4739), you need to use the legacy Hyper-V.

## quick start

- download [`docker-compose.yml`](https://github.com/8ctopus/apache-php-fpm-alpine/blob/master/docker-compose.yml)
- for php 8.1, 8.0 or 7.4, select image in `docker-compose.yml`
- start `Docker Desktop` and run `docker-compose up`
- open browser at [`http://localhost`](http://localhost)
- check provided examples

_Note_: If you also need a database, check my other project [php sandbox](https://github.com/8ctopus/php-sandbox).

## use container

Starting the container with `docker-compose` offers all functionalities.

```sh
# start container in detached mode on Windows in cmd
start /B docker-compose up

# start container in detached mode on linux, mac and mintty
docker-compose up &

# view logs
docker-compose logs -f

# stop container
docker-compose stop

# delete container
docker-compose down
```

Alternatively the container can also be started with `docker run`.

```sh
# php 8.2
docker run -p 80:80 -p 443:443 --name web 8ct8pus/apache-php-fpm-alpine:1.4.1

CTRL-C to stop
```

## access website

    http://localhost/
    https://localhost/

The source code is located inside the `html` directory.

## set domain name

To set the domain name to www.test.com, edit the environment variable in the `docker-compose.yml` file

    environment:
      - DOMAIN=www.test.com

Add this line to the system host file. Editing the file requires administrator privileges.

    C:\Windows\System32\drivers\etc\hosts

    127.0.0.1 test.net www.test.net

## add https

To remove "Your connection is not private" nag screens, import the certificate authority file under `docker/ssl/certificate_authority.pem` in the browser's certificates under Trusted Root Certification Authorities.

guide: https://support.globalsign.com/digital-certificates/digital-certificate-installation/install-client-digital-certificate-windows-using-chrome

## Xdebug debugger

This repository is configured to debug php code in Visual Studio Code. To start debugging, open the VSCode workspace then select `Run > Start debugging` then open the site in the browser.
The default config is to stop on entry which stops at the first line in the file. To only stop on breakpoints, set `stopOnEntry` to `false` in `.vscode/launch.json`.

For other IDEs, set the Xdebug debugging port to `9001`.

To troubleshoot debugger issues, check the `docker/log/xdebug.log` file.

If `host.docker.internal` does not resolve within the container, update the xdebug client host within `docker/etc/php/conf.d/xdebug.ini` to the docker host ip address.

```ini
xdebug.client_host = 192.168.65.2
```

## Code profiling

Code profiling comes in 2 variants.

_Note_: Disable Xdebug debugger `xdebug.remote_enable` for accurate measurements.

## Xdebug

To start profiling, add the `XDEBUG_PROFILE` variable to the request as a GET, POST or COOKIE.

    http://localhost/?XDEBUG_PROFILE

Profiles are stored in the `log` directory and can be analyzed with tools such as [webgrind](https://github.com/jokkedk/webgrind).

## SPX

- Access the [SPX control panel](http://localhost/?SPX_KEY=dev&SPX_UI_URI=/)
- Check checkbox `Whether to enable SPX profiler for your current browser session. No performance impact for other clients.`
- Run the script to profile
- Refresh the SPX control panel tab and the report will be available at the bottom of the screen. Click it to show the report in a new tab.

## access container command line

```sh
docker exec -it web zsh
```

## install more php extensions

```sh
docker exec -it web zsh

apk add php82-<extension>
```

## extend docker image

Let's extend this docker image by adding the `php-curl` extension.

```sh
docker-compose up --detach
docker exec -it web zsh
apk add php-curl
exit

docker-compose stop
docker commit web apache-php-fpm-alpine-curl:dev
```

To use newly created image, update the image reference in `docker-compose.yml`.

## development image

- build docker development image

```sh
docker build -t apache-php-fpm-alpine:dev .
```

- `rm -rf docker/`
- in docker-compose.yml

```yaml
services:
  web:
    # development image
    image: apache-php-fpm-alpine:dev
```

## update docker image

When you update the docker image version in `docker-compose.yml`, it's important to know that the existing configuration in the `docker` dir may cause problems.\
To solve all problems, backup the existing dir then delete it.

## release docker image

_Note_: Only for repository owner

```sh
# build php spx module
./php-spx/build.sh

# build local image
docker build -t 8ct8pus/apache-php-fpm-alpine:1.4.1 .

# test local image

# push image to docker hub
docker push 8ct8pus/apache-php-fpm-alpine:1.4.1
```

## more info on php-fpm

    https://php-fpm.org/about/
