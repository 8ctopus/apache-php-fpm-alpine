## project description

A super light docker web server with Apache and php-fpm on top of Alpine Linux for development purposes

- Apache 2.4.41 with SSL
- php-fpm 7.3.16
- Xdebug debugging from host
- composer
- zsh

The docker image size is 48 MB.

## cool features

- Apache and php configuration files are exposed on the host.
- Just works with any domain name.
- https is configured out of the box.
- All changes to the config files are automatically applied (hot reload).
- Xdebug is configured for remote debugging (no headaches).

## start container

    docker-compose up

    docker run -p 8000:80 8ct8pus/apache-php-fpm-alpine:latest

## access website

    http://localhost:8000/
    https://localhost:8001/

## set domain name

To set the domain name to www.test.com, edit the environment variable in the docker-compose file

    environment:
      - DOMAIN=www.test.com

Then edit the system host file (C:\Windows\System32\drivers\etc\hosts). Editing the file requires administrator privileges.

    127.0.0.1 test.net
    127.0.0.1 www.test.net

To access the site

    http://www.test.net:8000/
    https://www.test.net:8001/

## Xdebug

The docker image is fully configured to debug php code from the PC.
In the Xdebug client on the computer set the variables as follows:

    host: 127.0.0.1
    port: 9000
    path mapping: "/var/www/site/" : "$GIT_ROOT/dev/"

For path mapping, $GIT_ROOT is the absolute path to where you cloned this
repository in.

## build docker image

    docker build -t 8ct8pus/apache-php-fpm-alpine:latest .

## get console to container

    docker exec -it dev-web zsh

## extend the docker image

In this example, we add the php-curl extension.

    docker-compose up --detach
    docker exec -it dev-web zsh
    apk add php-curl
    exit
    docker-compose stop
    docker commit dev-web user/apache-php-fpm-alpine-curl:latest

To use the new image, run it or update the image link in the docker-compose file.
