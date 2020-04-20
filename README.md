## project description

A super light docker web server with Apache and php-fpm on top of Alpine Linux for development purposes

- Apache 2.4.41 with SSL
- php-fpm 7.3.17
- Xdebug debugging from host
- composer
- zsh

The docker image size is 40 MB.

## cool features

- Apache and php configuration files are exposed on the host.
- Just works with any domain name.
- https is configured out of the box.
- All changes to the config files are automatically applied (hot reload).
- Xdebug is configured for remote debugging (no headaches).

## start container

    docker-compose up

## access website

    http://localhost/
    https://localhost/

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
    port: 9001
    path mapping: "/var/www/site/" : "$GIT_ROOT/dev/"

For path mapping, $GIT_ROOT is the absolute path to where you cloned this
repository in.

## build docker image

    docker build -t apache-php-fpm-alpine:dev .

## get console to container

    docker exec -it lamp zsh

## extend the docker image

In this example, we add the php-curl extension.

    docker-compose up --detach
    docker exec -it lamp zsh
    apk add php-curl
    exit
    docker-compose stop
    docker commit lamp apache-php-fpm-alpine-curl:dev

To use the new image, run it or update the image link in the docker-compose file.

## more info on php-fpm

    https://php-fpm.org/about/
