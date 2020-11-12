## project description

A super light docker web server with Apache and php-fpm on top of Alpine Linux for development purposes

- Apache 2.4.46 with SSL
- php-fpm 7.4.12
- Xdebug 2.9.8 - debugger and profiler
- [SPX prolifer 0.4.10](https://github.com/NoiseByNorthwest/php-spx)
- composer 2.0.6
- zsh

The docker image size is 41 MB.

## cool features

- Apache and php configuration files are exposed on the host.
- Just works with any domain name.
- https is configured out of the box.
- All changes to the config files are automatically applied (hot reload).
- Xdebug is configured for remote debugging (no headaches).

## start container

Starting the container with `docker-compose` offer all container functionalities.

```bash
docker-compose up
CTRL-Z to detach

docker-compose stop
```

Alternatively the container can also be started with `docker run`.

```bash
docker run -p 80:80 -p 443:443 --name web 8ct8pus/apache-php-fpm-alpine:latest
CTRL-Z to detach

docker stop container
```

## access website

    http://localhost/
    https://localhost/

The source code is located inside the `html` directory.

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

This repository is configured to debug php code in Visual Studio Code.
To start debugging, open the VSCode workspace then select `Run > Start debugging` then open the site in the browser.

For other IDEs, set the Xdebug debugging port to 9001.

To troubleshoot debugger issues, check the `xdebug.log` file.

## Xdebug profiling

To start profiling, add the `XDEBUG_PROFILE` variable to the request as a GET, POST or COOKIE.

    http://localhost/?XDEBUG_PROFILE

Profiles are stored in the log directory and can be analyzed with tools such as [webgrind](https://github.com/jokkedk/webgrind).

## SPX profiling

To start profiling with SPX:

- Access the [SPX control panel](http://localhost/?SPX_KEY=dev&SPX_UI_URI=/)
- Check checkbox `Whether to enable SPX profiler for your current browser session. No performance impact for other clients.`
- Run script to profile
- Refresh the SPX control panel tab and the report will be available at the bottom of the screen. Click it to show the report in a new tab.
- 
## access container through command line

```bash
docker exec -it web zsh
```

## build docker image

```bash
docker build -t apache-php-fpm-alpine:dev .
```

## extend docker image

In this example, we add the php-curl extension.

```bash
docker-compose up --detach
docker exec -it web zsh
apk add php-curl
exit
docker-compose stop
docker commit web apache-php-fpm-alpine-curl:dev
```

To use the new image, update the image link in the docker-compose file.

## more info on php-fpm

    https://php-fpm.org/about/

## notes

In Windows hot reload doesn't work with WSL 2, you need to use the legacy Hyper-V.
