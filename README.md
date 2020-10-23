## project description

A super light docker web server with Apache and php-fpm on top of Alpine Linux for development purposes

- Apache 2.4.46 with SSL
- php-fpm 7.3.23
- Xdebug debugging from host
- composer
- zsh

The docker image size is 41 MB.

## cool features

- Apache and php configuration files are exposed on the host.
- Just works with any domain name.
- https is configured out of the box.
- All changes to the config files are automatically applied (hot reload).
- Xdebug is configured for remote debugging (no headaches).

## start container

```bash
docker-compose up
```

## access website

    http://localhost/
    https://localhost/

## set domain name

To set the domain name to www.test.com, edit the environment variable in the docker-compose file

    environment:
      - DOMAIN=www.test.com

Add this line to the system host file. Editing the file requires administrator privileges.

    C:\Windows\System32\drivers\etc\hosts

    127.0.0.1 test.net www.test.net

## https

To remove "Your connection is not private" nag screens, import the certificate authority file under ssl/certificate_authority.pem in your browser's certificates under Trusted Root Certification Authorities. (https://support.globalsign.com/digital-certificates/digital-certificate-installation/install-client-digital-certificate-windows-using-chrome)

## Xdebug

The docker image is fully configured to debug php code from the PC.
In the Xdebug client on the computer configure as follows:

    host: 127.0.0.1
    port: 9001
    path mapping: "/var/www/site/" : "$GIT_ROOT/dev/"

For path mapping, $GIT_ROOT is the absolute path to where you cloned this
repository in.

## build docker image

```bash
docker build -t apache-php-fpm-alpine:dev .
```

## get console to container

```bash
docker exec -it lap-fpm zsh
```

## extend the docker image

In this example, we add the php-curl extension.

```bash
docker-compose up --detach
docker exec -it lap-fpm zsh
apk add php-curl
exit
docker-compose stop
docker commit lap-fpm apache-php-fpm-alpine-curl:dev
```

To use the new image, update the image link in the docker-compose file.

## more info on php-fpm

    https://php-fpm.org/about/
