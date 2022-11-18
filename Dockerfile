FROM alpine:3.17.0_rc1
LABEL maintainer="8ctopus <hello@octopuslabs.io>"

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

## add testing repository
#RUN echo " https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# update apk repositories
RUN apk update

# upgrade all
RUN apk upgrade

# add tini https://github.com/krallin/tini/issues/8
RUN apk add tini

# install latest certificates for ssl
RUN apk add ca-certificates

# install console tools
RUN apk add \
    inotify-tools

# install zsh
RUN apk add \
    zsh \
    zsh-vcs

# configure zsh
COPY --chown=root:root include/zshrc /etc/zsh/zshrc

# install php
RUN apk add \
    php81 \
#    php81-apache2 \
    php81-bcmath \
#    php81-brotli \
    php81-bz2 \
    php81-calendar \
#    php81-cgi \
    php81-common \
    php81-ctype \
    php81-curl \
#    php81-dba \
#    php81-dbg \
#    php81-dev \
#    php81-doc \
    php81-dom \
#    php81-embed \
#    php81-enchant \
    php81-exif \
#    php81-ffi \
    php81-fileinfo \
    php81-ftp \
    php81-gd \
    php81-gettext \
#    php81-gmp \
    php81-json \
    php81-iconv \
    php81-imap \
    php81-intl \
    php81-ldap \
#    php81-litespeed \
    php81-mbstring \
    php81-mysqli \
#    php81-mysqlnd \
#    php81-odbc \
    php81-opcache \
    php81-openssl \
    php81-pcntl \
    php81-pdo \
    php81-pdo_mysql \
#    php81-pdo_odbc \
#    php81-pdo_pgsql \
    php81-pdo_sqlite \
#    php81-pear \
#    php81-pgsql \
    php81-phar \
#   php81-phpdbg \
    php81-posix \
#    php81-pspell \
    php81-session \
#    php81-shmop \
    php81-simplexml \
#    php81-snmp \
#    php81-soap \+
#    php81-sockets \
    php81-sodium \
    php81-sqlite3 \
#    php81-sysvmsg \
#    php81-sysvsem \
#    php81-sysvshm \
#    php81-tideways_xhprof \
#    php81-tidy \
    php81-tokenizer \
    php81-xml \
    php81-xmlreader \
    php81-xmlwriter \
    php81-zip

# use php81-fpm instead of php81-apache
RUN apk add php81-fpm

# i18n
RUN apk add \
    icu-data-full

# fix php iconv
# https://stackoverflow.com/questions/70046717/iconv-error-when-running-statamic-laravel-seo-pro-plugin-with-phpfpm-alpine
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# add symbolic link for php
#RUN ln -s /usr/bin/php81 /usr/bin/php

# PECL extensions
RUN apk add \
#    php81-pecl-amqp \
#    php81-pecl-apcu \
#    php81-pecl-ast \
#    php81-pecl-couchbase \
#    php81-pecl-event \
#    php81-pecl-igbinary \
#    php81-pecl-imagick \
#    php81-pecl-imagick-dev \
#    php81-pecl-lzf \
#    php81-pecl-mailparse \
#    php81-pecl-maxminddb \
#    php81-pecl-mcrypt \
#    php81-pecl-memcache \
#    php81-pecl-memcached \
#    php81-pecl-mongodb \
#    php81-pecl-msgpack \
#    php81-pecl-oauth \
#    php81-pecl-protobuf \
#    php81-pecl-psr \
#    php81-pecl-rdkafka \
#    php81-pecl-redis \
#    php81-pecl-ssh2 \
#    php81-pecl-timezonedb \
#    php81-pecl-uploadprogress \
#    php81-pecl-uploadprogress-doc \
#    php81-pecl-uuid \
#    php81-pecl-vips \
    php81-pecl-xdebug
#    php81-pecl-xhprof \
#    php81-pecl-xhprof-assets \
#    php81-pecl-yaml \
#    php81-pecl-zstd \
#    php81-pecl-zstd-dev

# configure xdebug
COPY --chown=root:root include/xdebug.ini /etc/php81/conf.d/xdebug.ini

# install composer (currently installs php8.1 which creates a mess, use script approach instead to install)
#RUN apk add \
#    composer

# add composer script
COPY --chown=root:root include/composer.sh /tmp/composer.sh

# make composer script executable
RUN chmod +x /tmp/composer.sh

# install composer
RUN /tmp/composer.sh

# move composer binary to usr bin
RUN mv /composer.phar /usr/bin/composer

# install apache
RUN apk add \
    apache2 \
    apache2-ssl \
    apache2-proxy

# delete apk cache
RUN rm -rf /var/cache/apk/*

# add user www-data
# group www-data already exists
# -H don't create home directory
# -D don't assign a password
# -S create a system user
RUN adduser -H -D -S -G www-data -s /sbin/nologin www-data

# update user and group apache runs under
RUN sed -i 's|User apache|User www-data|g' /etc/apache2/httpd.conf
RUN sed -i 's|Group apache|Group www-data|g' /etc/apache2/httpd.conf

# enable mod rewrite (rewrite urls in htaccess)
RUN sed -i 's|#LoadModule rewrite_module modules/mod_rewrite.so|LoadModule rewrite_module modules/mod_rewrite.so|g' /etc/apache2/httpd.conf

# enable important apache modules
RUN sed -i 's|#LoadModule deflate_module modules/mod_deflate.so|LoadModule deflate_module modules/mod_deflate.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule expires_module modules/mod_expires.so|LoadModule expires_module modules/mod_expires.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule ext_filter_module modules/mod_ext_filter.so|LoadModule ext_filter_module modules/mod_ext_filter.so|g' /etc/apache2/httpd.conf

# switch from mpm_prefork to mpm_event
RUN sed -i 's|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|g' /etc/apache2/httpd.conf

# authorize all directives in .htaccess
RUN sed -i 's|    AllowOverride None|    AllowOverride All|g' /etc/apache2/httpd.conf

# authorize all changes from htaccess
RUN sed -i 's|Options Indexes FollowSymLinks|Options All|g' /etc/apache2/httpd.conf

# configure php-fpm to run as www-data
RUN sed -i 's|user = nobody|user = www-data|g' /etc/php81/php-fpm.d/www.conf
RUN sed -i 's|group = nobody|group = www-data|g' /etc/php81/php-fpm.d/www.conf
RUN sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php81/php-fpm.d/www.conf
RUN sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php81/php-fpm.d/www.conf

# configure php-fpm to use unix socket
RUN sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php81/php-fpm.d/www.conf

# update apache timeout for easier debugging
RUN sed -i 's|^Timeout .*$|Timeout 600|g' /etc/apache2/conf.d/default.conf

# add vhosts to apache
RUN echo -e "\n# Include the virtual host configurations:\nIncludeOptional /sites/config/vhosts/*.conf" >> /etc/apache2/httpd.conf

# set localhost server name
RUN sed -i "s|#ServerName .*:80|ServerName localhost:80|g" /etc/apache2/httpd.conf

# update php max execution time for easier debugging
RUN sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php81/php.ini

# php log everything
RUN sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php81/php.ini

# add php-spx
COPY --chown=root:root include/php-spx/assets/ /usr/share/misc/php-spx/assets/
COPY --chown=root:root include/php-spx/spx.so /usr/lib/php81/modules/spx.so
COPY --chown=root:root include/php-spx/spx.ini /etc/php81/conf.d/spx.ini

# add default sites
COPY --chown=root:root include/sites/ /sites.bak/

# add entry point script
COPY --chown=root:root include/start.sh /tmp/start.sh

# make entry point script executable
RUN chmod +x /tmp/start.sh

# set working dir
WORKDIR /sites/

# set entrypoint
ENTRYPOINT ["tini", "-vw"]

# run script
CMD ["/tmp/start.sh"]
