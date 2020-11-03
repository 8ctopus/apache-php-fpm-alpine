## project description

A super light docker web server with Apache and php-fpm on top of Alpine Linux for development purposes

- Apache 2.4.46 with SSL
- php-fpm 7.4.12
- Xdebug debugging
- Xdebug profiler
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
docker run -p 80:80 8ct8pus/apache-php-fpm-alpine
+ CTRL-Z to detach

docker stop container
```
or
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

To remove "Your connection is not private" nag screens, import the certificate authority file under ssl/certificate_authority.pem in the browser's certificates under Trusted Root Certification Authorities.

guide: https://support.globalsign.com/digital-certificates/digital-certificate-installation/install-client-digital-certificate-windows-using-chrome

## Xdebug debugging

The docker image is configured to debug php code in Visual Studio Code.
To start debugging `Run > Start debugging` then load `index.php` in the browser.

For other IDEs, set port to 9001.

## Xdebug profiling

The docker image is configured to profile php code.
To start profiling, add the `XDEBUG_PROFILE` variable to the request as a GET, POST or COOKIE.

    http://localhost/?XDEBUG_PROFILE

Profiles are stored in the log directory.

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

## notes

In Windows hot reload doesn't work with WSL 2, you need to use the legacy Hyper-V.

