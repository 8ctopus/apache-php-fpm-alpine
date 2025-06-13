# don't use alpine:edge as it is not refreshed that often
FROM alpine:3.22.0 AS image
LABEL maintainer="8ctopus <hello@octopuslabs.io>"

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

# update repositories to edge
RUN printf "https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\n" > /etc/apk/repositories && \
    # add testing repository
    printf "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing\n" >> /etc/apk/repositories && \
    # update apk repositories
    apk update && \
    # upgrade all
    apk upgrade

# add tini https://github.com/krallin/tini/issues/8
RUN apk add --no-cache tini \
    # install latest certificates for ssl
    ca-certificates@testing \
    # install console tools
    inotify-tools@testing \
    # install zsh
    zsh@testing \
    zsh-vcs@testing \
    # install php
    php83@testing \
#    php83-apache2@testing \
    php83-bcmath@testing \
    php83-brotli@testing \
    php83-bz2@testing \
    php83-calendar@testing \
#    php83-cgi@testing \
    php83-common@testing \
    php83-ctype@testing \
    php83-curl@testing \
#    php83-dba@testing \
#    php83-dbg@testing \
#    php83-dev@testing \
#    php83-doc@testing \
    php83-dom@testing \
#    php83-embed@testing \
#    php83-enchant@testing \
    php83-exif@testing \
#    php83-ffi@testing \
    php83-fileinfo@testing \
    php83-ftp@testing \
    php83-gd@testing \
    php83-gettext@testing \
#    php83-gmp@testing \
    php83-json@testing \
    php83-iconv@testing \
    php83-imap@testing \
    php83-intl@testing \
    php83-ldap@testing \
#    php83-litespeed@testing \
    php83-mbstring@testing \
    php83-mysqli@testing \
#    php83-mysqlnd@testing \
#    php83-odbc@testing \
    php83-opcache@testing \
    php83-openssl@testing \
    php83-pcntl@testing \
    php83-pdo@testing \
    php83-pdo_mysql@testing \
#    php83-pdo_odbc@testing \
#    php83-pdo_pgsql@testing \
    php83-pdo_sqlite@testing \
#    php83-pear@testing \
#    php83-pgsql@testing \
    php83-phar@testing \
#   php83-phpdbg@testing \
    php83-posix@testing \
#    php83-pspell@testing \
    php83-session@testing \
#    php83-shmop@testing \
    php83-simplexml@testing \
#    php83-snmp@testing \
#    php83-soap@testing \+
#    php83-sockets@testing \
    php83-sodium@testing \
    php83-sqlite3@testing \
#    php83-sysvmsg@testing \
#    php83-sysvsem@testing \
#    php83-sysvshm@testing \
#    php83-tideways_xhprof@testing \
#    php83-tidy@testing \
    php83-tokenizer@testing \
    php83-xml@testing \
    php83-xmlreader@testing \
    php83-xmlwriter@testing \
    php83-zip@testing \
    # use php83-fpm instead of php83-apache
    php83-fpm@testing \
    # i18n
    icu-data-full

# PECL extensions
RUN apk add --no-cache \
#    php83-pecl-amqp@testing \
#    php83-pecl-apcu@testing \
#    php83-pecl-ast@testing \
#    php83-pecl-couchbase@testing \
#    php83-pecl-event@testing \
#    php83-pecl-igbinary@testing \
#    php83-pecl-imagick@testing \
#    php83-pecl-imagick-dev@testing \
#    php83-pecl-lzf@testing \
#    php83-pecl-mailparse@testing \
#    php83-pecl-maxminddb@testing \
#    php83-pecl-mcrypt@testing \
#    php83-pecl-memcache@testing \
#    php83-pecl-memcached@testing \
#    php83-pecl-mongodb@testing \
#    php83-pecl-msgpack@testing \
#    php83-pecl-oauth@testing \
#    php83-pecl-protobuf@testing \
#    php83-pecl-psr@testing \
#    php83-pecl-rdkafka@testing \
#    php83-pecl-redis@testing \
#    php83-pecl-ssh2@testing \
#    php83-pecl-timezonedb@testing \
#    php83-pecl-uploadprogress@testing \
#    php83-pecl-uploadprogress-doc@testing \
#    php83-pecl-uuid@testing \
#    php83-pecl-vips@testing \
    php83-pecl-xdebug@testing
#    php83-pecl-xhprof@testing \
#    php83-pecl-xhprof-assets@testing \
#    php83-pecl-yaml@testing \
#    php83-pecl-zstd@testing \
#    php83-pecl-zstd-dev@testing

# fix iconv(): Wrong encoding, conversion from &quot;UTF-8&quot; to &quot;UTF-8//IGNORE&quot; is not allowed
# This error occurs when there's an issue with the iconv library's handling of character encoding conversion,
# specifically when trying to convert from UTF-8 to US-ASCII with TRANSLIT option.
# This is a common issue in Alpine Linux-based PHP images because Alpine uses musl libc which includes a different
# implementation of iconv than the more common GNU libiconv.
RUN apk add --no-cache --no-cache  --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3
ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

# install composer (currently installs php8.1 which creates a mess, use script approach instead to install)
#RUN apk add --no-cache \
#    composer@testing

# create php aliases
#RUN ln -s /usr/bin/php84 /usr/bin/php
RUN ln -s /usr/sbin/php-fpm83 /usr/sbin/php-fpm

# configure zsh
COPY --chown=root:root include/zshrc /etc/zsh/zshrc

# configure xdebug
COPY --chown=root:root include/xdebug.ini /etc/php83/conf.d/xdebug.ini

# add composer script
COPY --chown=root:root include/composer.sh /tmp/composer.sh

# make composer script executable
RUN chmod +x /tmp/composer.sh

# install composer
RUN /tmp/composer.sh

# move composer binary to usr bin
RUN mv /composer.phar /usr/bin/composer

# install self-signed certificate generator
COPY --chown=root:root include/selfsign.sh /tmp/selfsign.sh
RUN chmod +x /tmp/selfsign.sh
RUN /tmp/selfsign.sh
RUN mv /selfsign.phar /usr/bin/selfsign
RUN chmod +x /usr/bin/selfsign

# install apache
RUN apk add --no-cache \
    apache2@testing \
    apache2-ssl@testing \
    apache2-proxy@testing

# delete apk cache (FIX ME this has no effect because of layer immutability)
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
RUN sed -i 's|user = nobody|user = www-data|g' /etc/php83/php-fpm.d/www.conf
RUN sed -i 's|group = nobody|group = www-data|g' /etc/php83/php-fpm.d/www.conf
RUN sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php83/php-fpm.d/www.conf
RUN sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php83/php-fpm.d/www.conf

# configure php-fpm to use unix socket
RUN sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php83/php-fpm.d/www.conf

# update apache timeout for easier debugging
RUN sed -i 's|^Timeout .*$|Timeout 600|g' /etc/apache2/conf.d/default.conf

# add vhosts to apache
RUN echo -e "\n# Include the virtual host configurations:\nIncludeOptional /sites/config/vhosts/*.conf" >> /etc/apache2/httpd.conf

# set localhost server name
RUN sed -i "s|#ServerName .*:80|ServerName localhost:80|g" /etc/apache2/httpd.conf

# update php max execution time for easier debugging
RUN sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php83/php.ini

# update max upload size
RUN sed -i 's|^upload_max_filesize = 2M$|upload_max_filesize = 20M|g' /etc/php83/php.ini

# php log everything
RUN sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php83/php.ini

# add php-spx
COPY --chown=root:root include/php-spx/assets/ /usr/share/misc/php-spx/assets/
COPY --chown=root:root include/php-spx/spx.so /usr/lib/php83/modules/spx.so
COPY --chown=root:root include/php-spx/spx.ini /etc/php83/conf.d/spx.ini

# add default sites
COPY --chown=www-data:www-data include/sites/ /sites.bak/

# add entry point script
COPY --chown=root:root include/start.sh /tmp/start.sh

# make entry point script executable
RUN chmod +x /tmp/start.sh

# set working dir
RUN mkdir /sites/
RUN chown www-data:www-data /sites/
WORKDIR /sites/

# set entrypoint
ENTRYPOINT ["tini", "-vw"]

# run script
CMD ["/tmp/start.sh"]
