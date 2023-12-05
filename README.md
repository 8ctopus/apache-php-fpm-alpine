# docker apache php-fpm alpine

![Docker image size (latest semver)](https://img.shields.io/docker/image-size/8ct8pus/apache-php-fpm-alpine?sort=semver)
![Docker image pulls](https://img.shields.io/docker/pulls/8ct8pus/apache-php-fpm-alpine)
[image on dockerhub](https://hub.docker.com/r/8ct8pus/apache-php-fpm-alpine)

A super light docker web server with Apache and php-fpm on top of Alpine Linux for php developers.

- Apache 2.4.58 with SSL
- php-fpm 8.3, 8.2, 8.1, 8.0 or 7.4
- Xdebug 3.3.0 - debugger and profiler
- composer 2.6.5
- [SPX prolifer dev-master](https://github.com/NoiseByNorthwest/php-spx)
- zsh 5.9
- Alpine 3.18.5 using edge repositories

_Note_: If you need a fully-fledged development environment, checkout the [php sandbox](https://github.com/8ctopus/php-sandbox) project.

## cool features

- php along with the most commonly used extensions
- Just works with any domain name
- Support for multiple virtual hosts
- https is configured out of the box
- Apache and php configuration files are exposed on the host for easy editing
- All changes to configuration files are automatically applied (hot reload)
- Xdebug is configured for step by step debugging and profiling
- Profile php code with SPX or Xdebug

## quick start

- download [`docker-compose.yml`](https://github.com/8ctopus/apache-php-fpm-alpine/blob/master/docker-compose.yml)
- php 8.3 is the default flavor, to use php 8.2, 8.1, 8.0 or 7.4, select the image in `docker-compose.yml`
- start `Docker Desktop` and run `docker-compose up`
- open browser at [`http://localhost/`](http://localhost/)

_Note_: On Windows [hot reload doesn't work with WSL 2](https://github.com/microsoft/WSL/issues/4739), you need to use the legacy Hyper-V.

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
# php 8.3
docker run -p 80:80 -p 443:443 --name web 8ct8pus/apache-php-fpm-alpine:2.2.0

# php 8.2
docker run -p 80:80 -p 443:443 --name web 8ct8pus/apache-php-fpm-alpine:2.1.3

CTRL-C to stop
```

## access sites

There are 2 sites you can access from your browser

    http(s)://localhost/
    http(s)://(www.)test.com/

The source code is located inside the `sites/*/html/public/` directories.

## domain names

Setting a domain name is done by using virtual hosts. The virtual hosts configuration files are located in `sites/config/vhosts/`. By default, `localhost` and `test.com` are already defined as virtual hosts.

For your browser to resolve `test.com`, add this line to your system's host file. Editing the file requires administrator privileges.\
\
On Windows: `C:\Windows\System32\drivers\etc\hosts`\
Linux and Mac: `/etc/hosts`

    127.0.0.1 test.com www.test.com

## https

A self-signed https certificate is already configured for `localhost` and `test.com`.\
To remove "Your connection is not private" nag screens, import the certificate authority file `sites/config/ssl/certificate_authority.pem` to your computer's Trusted Root Certification Authorities then restart your browser.

In Windows, open `certmgr.msc` > click `Trusted Root Certification Authorities`, then right click on that folder and select `Import...` under `All Tasks`.

On Linux and Mac: \[fill blank\]

For newly created domains, you will need to create the SSL certificate:

```sh
docker-exec -it web zsh
selfsign certificate /sites/domain/ssl domain.com,www.domain.com,api.domain.com /sites/config/ssl
```

_Note_: Importing the certificate authority creates a security risk since all certificates issued by this new authority are shown as perfectly valid in your browsers.

## Xdebug debugger

This repository is configured to debug php code in Visual Studio Code. To start debugging, open the VSCode workspace then select `Run > Start debugging` then open the site in the browser.\
The default config is to stop on entry which stops at the first line in the file. To only stop on breakpoints, set `stopOnEntry` to `false` in `.vscode/launch.json`.

For other IDEs, set the Xdebug debugging port to `9001`.

To troubleshoot debugger issues, check the `sites/localhost/logs/xdebug.log` file.

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

## update docker image

When you update the docker image version in `docker-compose.yml`, it's important to know that the existing configuration in the `docker` dir may cause problems.\
To solve all problems, backup the existing dir then delete it.

## build development image

```sh
docker build -t apache-php-fpm-alpine:dev .
```

- update `docker-compose.yml` and uncomment the development image

```yaml
services:
  web:
    # development image
    image: apache-php-fpm-alpine:dev
```

## build docker image

_Note_: Only for repository owner

```sh
# build php spx module
./php-spx/build.sh

# bump version

# build local image
docker build --no-cache -t 8ct8pus/apache-php-fpm-alpine:2.2.0 .

# test local image

# push image to docker hub
docker push 8ct8pus/apache-php-fpm-alpine:2.2.0
```

## more info on php-fpm

    https://php-fpm.org/about/
