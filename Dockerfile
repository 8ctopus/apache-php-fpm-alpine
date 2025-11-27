FROM alpine:3.22.2 AS mailpit

RUN apk add --no-cache upx

RUN wget https://github.com/axllent/mailpit/releases/download/v1.27.11/mailpit-linux-amd64.tar.gz -O mailpit.tar.gz
RUN tar --extract --file mailpit.tar.gz
# compress mailpit as it weighs around 24Mb
RUN upx mailpit

# don't use alpine:edge as it is not refreshed that often
FROM alpine:3.22.2 AS image
LABEL maintainer="8ctopus <hello@octopuslabs.io>"

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

RUN \
    # update repositories to edge
    printf "https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\n" > /etc/apk/repositories && \
    # add testing repository
    printf "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing\n" >> /etc/apk/repositories && \
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
    ca-certificates@testing \
    \
    # install console tools
    inotify-tools@testing \
    \
    # install zsh
    zsh@testing \
    zsh-vcs@testing \
    \
    # install php
    php85@testing \
#    php85-apache2@testing \
    php85-bcmath@testing \
    php85-brotli@testing \
    php85-bz2@testing \
    php85-calendar@testing \
#    php85-cgi@testing \
    php85-common@testing \
    php85-ctype@testing \
    php85-curl@testing \
#    php85-dba@testing \
#    php85-dbg@testing \
#    php85-dev@testing \
#    php85-doc@testing \
    php85-dom@testing \
#    php85-embed@testing \
#    php85-enchant@testing \
    php85-exif@testing \
#    php85-ffi@testing \
    php85-fileinfo@testing \
    php85-ftp@testing \
    php85-gd@testing \
    php85-gettext@testing \
#    php85-gmp@testing \
    php85-json@testing \
    php85-iconv@testing \
    php85-imap@testing \
    php85-intl@testing \
    php85-ldap@testing \
#    php85-litespeed@testing \
    php85-mbstring@testing \
    php85-mysqli@testing \
#    php85-mysqlnd@testing \
#    php85-odbc@testing \
#    php85-opcache@testing \
    php85-openssl@testing \
    php85-pcntl@testing \
    php85-pdo@testing \
    php85-pdo_mysql@testing \
#    php85-pdo_odbc@testing \
#    php85-pdo_pgsql@testing \
    php85-pdo_sqlite@testing \
#    php85-pear@testing \
#    php85-pgsql@testing \
    php85-phar@testing \
#   php85-phpdbg@testing \
    php85-posix@testing \
#    php85-pspell@testing \
    php85-session@testing \
#    php85-shmop@testing \
    php85-simplexml@testing \
#    php85-snmp@testing \
#    php85-soap@testing \
#    php85-sockets@testing \
    php85-sodium@testing \
    php85-sqlite3@testing \
#    php85-sysvmsg@testing \
#    php85-sysvsem@testing \
#    php85-sysvshm@testing \
#    php85-tideways_xhprof@testing \
#    php85-tidy@testing \
    php85-tokenizer@testing \
    php85-xml@testing \
    php85-xmlreader@testing \
    php85-xmlwriter@testing \
    php85-zip@testing \
    \
    # use php85-fpm instead of php85-apache
    php85-fpm@testing \
    \
    # i18n
    icu-data-full \
    \
    # PECL extensions
#    php85-pecl-amqp@testing \
#    php85-pecl-apcu@testing \
#    php85-pecl-ast@testing \
#    php85-pecl-couchbase@testing \
#    php85-pecl-event@testing \
#    php85-pecl-igbinary@testing \
#    php85-pecl-imagick@testing \
#    php85-pecl-imagick-dev@testing \
#    php85-pecl-lzf@testing \
#    php85-pecl-mailparse@testing \
#    php85-pecl-maxminddb@testing \
#    php85-pecl-mcrypt@testing \
#    php85-pecl-memcache@testing \
#    php85-pecl-memcached@testing \
#    php85-pecl-mongodb@testing \
#    php85-pecl-msgpack@testing \
#    php85-pecl-oauth@testing \
#    php85-pecl-protobuf@testing \
#    php85-pecl-psr@testing \
#    php85-pecl-rdkafka@testing \
#    php85-pecl-redis@testing \
#    php85-pecl-ssh2@testing \
#    php85-pecl-timezonedb@testing \
#    php85-pecl-uploadprogress@testing \
#    php85-pecl-uploadprogress-doc@testing \
#    php85-pecl-uuid@testing \
#    php85-pecl-vips@testing \
    php85-pecl-xdebug@testing \
#    php85-pecl-xhprof@testing \
#    php85-pecl-xhprof-assets@testing \
#    php85-pecl-yaml@testing \
#    php85-pecl-zstd@testing \
#    php85-pecl-zstd-dev@testing
    \
    # install apache
    apache2@testing \
    apache2-ssl@testing \
    apache2-proxy@testing && \
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
    # create php aliases
    ln -s /usr/bin/php85 /usr/bin/php && \
    ln -s /usr/sbin/php-fpm85 /usr/sbin/php-fpm && \
    \
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
