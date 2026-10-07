FROM alpine:3.24.2 AS mailpit

RUN apk add --no-cache upx

RUN wget https://github.com/axllent/mailpit/releases/download/v1.31.3/mailpit-linux-amd64.tar.gz -O mailpit.tar.gz
RUN tar --extract --file mailpit.tar.gz
# compress mailpit as it weighs around 24Mb
RUN upx mailpit

# don't use alpine:edge as it is not refreshed that often
FROM alpine:3.24.2 AS image
LABEL maintainer="8ctopus <hello@octopuslabs.io>"

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

RUN \
    # update repositories to edge
    printf "https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\n" > /etc/apk/repositories && \
    ## add testing repository
    #printf "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing\n" >> /etc/apk/repositories && \
    \
    # update apk repositories
    apk update && \
    # upgrade all packages
    apk upgrade && \
    \
    apk add --no-cache \
    # add tini https://github.com/krallin/tini/issues/8
    tini \
    \
    # install latest certificates for ssl
    ca-certificates \
    \
    # install console tools
    inotify-tools \
    \
    # install zsh
    zsh \
    zsh-vcs \
    \
    # install php
    php85 \
#    php85-apache2 \
    php85-bcmath \
    php85-brotli \
    php85-bz2 \
    php85-calendar \
#    php85-cgi \
    php85-common \
    php85-ctype \
    php85-curl \
#    php85-dba \
#    php85-dbg \
#    php85-dev \
#    php85-doc \
    php85-dom \
#    php85-embed \
#    php85-enchant \
    php85-exif \
#    php85-ffi \
    php85-fileinfo \
    php85-ftp \
    php85-gd \
    php85-gettext \
#    php85-gmp \
    php85-json \
    php85-iconv \
    php85-imap \
    php85-intl \
    php85-ldap \
#    php85-litespeed \
    php85-mbstring \
    php85-mysqli \
#    php85-mysqlnd \
#    php85-odbc \
#    php85-opcache \
    php85-openssl \
    php85-pcntl \
    php85-pdo \
    php85-pdo_mysql \
#    php85-pdo_odbc \
#    php85-pdo_pgsql \
    php85-pdo_sqlite \
#    php85-pear \
#    php85-pgsql \
    php85-phar \
#   php85-phpdbg \
    php85-posix \
#    php85-pspell \
    php85-session \
#    php85-shmop \
    php85-simplexml \
#    php85-snmp \
#    php85-soap \
#    php85-sockets \
    php85-sodium \
    php85-sqlite3 \
#    php85-sysvmsg \
#    php85-sysvsem \
#    php85-sysvshm \
#    php85-tideways_xhprof \
#    php85-tidy \
    php85-tokenizer \
    php85-xml \
    php85-xmlreader \
    php85-xmlwriter \
    php85-zip \
    \
    # use php85-fpm instead of php85-apache
    php85-fpm \
    \
    # i18n
    icu-data-full \
    \
    # PECL extensions
#    php85-pecl-amqp \
#    php85-pecl-apcu \
#    php85-pecl-ast \
#    php85-pecl-couchbase \
#    php85-pecl-event \
#    php85-pecl-igbinary \
#    php85-pecl-imagick \
#    php85-pecl-imagick-dev \
#    php85-pecl-lzf \
#    php85-pecl-mailparse \
#    php85-pecl-maxminddb \
#    php85-pecl-mcrypt \
#    php85-pecl-memcache \
#    php85-pecl-memcached \
#    php85-pecl-mongodb \
#    php85-pecl-msgpack \
#    php85-pecl-oauth \
#    php85-pecl-protobuf \
#    php85-pecl-psr \
#    php85-pecl-rdkafka \
#    php85-pecl-redis \
#    php85-pecl-ssh2 \
#    php85-pecl-timezonedb \
#    php85-pecl-uploadprogress \
#    php85-pecl-uploadprogress-doc \
#    php85-pecl-uuid \
#    php85-pecl-vips \
    php85-pecl-xdebug \
#    php85-pecl-xhprof \
#    php85-pecl-xhprof-assets \
#    php85-pecl-yaml \
#    php85-pecl-zstd \
#    php85-pecl-zstd-dev
    \
    # install apache
    apache2 \
    apache2-ssl \
    apache2-proxy && \
    \
    # fix iconv(): Wrong encoding, conversion from &quot;UTF-8&quot; to &quot;UTF-8//IGNORE&quot; is not allowed
    # This error occurs when there's an issue with the iconv library's handling of character encoding conversion,
    # specifically when trying to convert from UTF-8 to US-ASCII with TRANSLIT option.
    # This is a common issue in Alpine Linux-based PHP images because Alpine uses musl libc which includes a different
    # implementation of iconv than the more common GNU libiconv.
    apk add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3 && \
    \
    # delete apk cache (needs to be done before the layer is written)
    rm -rf /var/cache/apk/*

ENV LD_PRELOAD=/usr/lib/preloadable_libiconv.so

RUN \
    # add user www-data
    # group www-data already exists
    # -H don't create home directory
    # -D don't assign a password
    # -S create a system user
    adduser -H -D -S -G www-data -s /sbin/nologin www-data && \
    \
    # update user and group apache runs under
    sed -i 's|User apache|User www-data|g' /etc/apache2/httpd.conf && \
    sed -i 's|Group apache|Group www-data|g' /etc/apache2/httpd.conf && \
    # enable mod rewrite (rewrite urls in htaccess)
    sed -i 's|#LoadModule rewrite_module modules/mod_rewrite.so|LoadModule rewrite_module modules/mod_rewrite.so|g' /etc/apache2/httpd.conf && \
    # enable important apache modules
    sed -i 's|#LoadModule deflate_module modules/mod_deflate.so|LoadModule deflate_module modules/mod_deflate.so|g' /etc/apache2/httpd.conf && \
    sed -i 's|#LoadModule expires_module modules/mod_expires.so|LoadModule expires_module modules/mod_expires.so|g' /etc/apache2/httpd.conf && \
    sed -i 's|#LoadModule ext_filter_module modules/mod_ext_filter.so|LoadModule ext_filter_module modules/mod_ext_filter.so|g' /etc/apache2/httpd.conf && \
    # switch from mpm_prefork to mpm_event
    sed -i 's|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|g' /etc/apache2/httpd.conf && \
    sed -i 's|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|g' /etc/apache2/httpd.conf && \
    # authorize all directives in .htaccess
    sed -i 's|    AllowOverride None|    AllowOverride All|g' /etc/apache2/httpd.conf && \
    # authorize all changes from htaccess
    sed -i 's|Options Indexes FollowSymLinks|Options All|g' /etc/apache2/httpd.conf && \
    # configure php-fpm to run as www-data
    sed -i 's|user = nobody|user = www-data|g' /etc/php85/php-fpm.d/www.conf && \
    sed -i 's|group = nobody|group = www-data|g' /etc/php85/php-fpm.d/www.conf && \
    sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php85/php-fpm.d/www.conf && \
    sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php85/php-fpm.d/www.conf && \
    # configure php-fpm to use unix socket
    sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php85/php-fpm.d/www.conf && \
    # update apache timeout for easier debugging
    sed -i 's|^Timeout .*$|Timeout 600|g' /etc/apache2/conf.d/default.conf && \
    # add vhosts to apache
    echo -e "\n# Include the virtual host configurations:\nIncludeOptional /sites/config/vhosts/*.conf" >> /etc/apache2/httpd.conf && \
    # set localhost server name
    sed -i "s|#ServerName .*:80|ServerName localhost:80|g" /etc/apache2/httpd.conf && \
    # update php max execution time for easier debugging
    sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php85/php.ini && \
    # update max upload size
    sed -i 's|^upload_max_filesize = 2M$|upload_max_filesize = 20M|g' /etc/php85/php.ini && \
    # php log everything
    sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php85/php.ini

COPY --chown=root:root include /tmp

RUN \
    ## create php aliases
    #ln -s /usr/bin/php85 /usr/bin/php && \
    #ln -s /usr/sbin/php-fpm85 /usr/sbin/php-fpm && \
    #\
    # configure zsh
    mv /tmp/zshrc /etc/zsh/zshrc && \
    # configure xdebug
    mv /tmp/xdebug.ini /etc/php85/conf.d/xdebug.ini && \
    \
    # install composer
    chmod +x /tmp/composer.sh && \
    /tmp/composer.sh && \
    mv /composer.phar /usr/bin/composer && \
    \
    # install self-signed certificate generator
    chmod +x /tmp/selfsign.sh && \
    /tmp/selfsign.sh && \
    mv /selfsign.phar /usr/bin/selfsign && \
    chmod +x /usr/bin/selfsign && \
    \
    # add php-spx - /usr/share/misc/php-spx/assets/web-ui
    mv /tmp/php-spx/spx.ini /etc/php85/conf.d/spx.ini && \
    mv /tmp/php-spx/spx.so /usr/lib/php85/modules/spx.so && \
    mkdir -p /usr/share/misc/php-spx/ && \
    mv /tmp/php-spx/assets /usr/share/misc/php-spx/ && \
    \
    # add default sites
    mv /tmp/sites/ /sites.bak/ && \
    # add entry point script
    #mv /tmp/start.sh /tmp/start.sh
    # make entry point script executable
    chmod +x /tmp/start.sh && \
    # set working dir
    mkdir /sites/ && \
    chown www-data:www-data /sites/ && \
    mkdir -p /sites/localhost/logs/ && \
    chown -R www-data:www-data /sites/localhost/logs

# add mailpit (intercept emails)
COPY --chown=root:root --from=mailpit /mailpit /usr/local/bin/mailpit
RUN chmod +x /usr/local/bin/mailpit && \
    ln -sf /usr/local/bin/mailpit /usr/sbin/sendmail

WORKDIR /sites/

# set entrypoint
ENTRYPOINT ["tini", "-vw"]

# run script
CMD ["/tmp/start.sh"]
