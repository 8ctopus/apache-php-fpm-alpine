FROM alpine:3.22.0 AS mailpit

RUN apk add --no-cache upx

RUN wget https://github.com/axllent/mailpit/releases/download/v1.26.0/mailpit-linux-amd64.tar.gz -O mailpit.tar.gz
RUN tar --extract --file mailpit.tar.gz
# compress mailpit as it weighs around 24Mb
RUN upx mailpit

# don't use alpine:edge as it is not refreshed that often
FROM alpine:3.22.0 AS image
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
    php84@testing \
#    php84-apache2@testing \
    php84-bcmath@testing \
    php84-brotli@testing \
    php84-bz2@testing \
    php84-calendar@testing \
#    php84-cgi@testing \
    php84-common@testing \
    php84-ctype@testing \
    php84-curl@testing \
#    php84-dba@testing \
#    php84-dbg@testing \
#    php84-dev@testing \
#    php84-doc@testing \
    php84-dom@testing \
#    php84-embed@testing \
#    php84-enchant@testing \
    php84-exif@testing \
#    php84-ffi@testing \
    php84-fileinfo@testing \
    php84-ftp@testing \
    php84-gd@testing \
    php84-gettext@testing \
#    php84-gmp@testing \
    php84-json@testing \
    php84-iconv@testing \
    php84-imap@testing \
    php84-intl@testing \
    php84-ldap@testing \
#    php84-litespeed@testing \
    php84-mbstring@testing \
    php84-mysqli@testing \
#    php84-mysqlnd@testing \
#    php84-odbc@testing \
    php84-opcache@testing \
    php84-openssl@testing \
    php84-pcntl@testing \
    php84-pdo@testing \
    php84-pdo_mysql@testing \
#    php84-pdo_odbc@testing \
#    php84-pdo_pgsql@testing \
    php84-pdo_sqlite@testing \
#    php84-pear@testing \
#    php84-pgsql@testing \
    php84-phar@testing \
#   php84-phpdbg@testing \
    php84-posix@testing \
#    php84-pspell@testing \
    php84-session@testing \
#    php84-shmop@testing \
    php84-simplexml@testing \
#    php84-snmp@testing \
#    php84-soap@testing \
#    php84-sockets@testing \
    php84-sodium@testing \
    php84-sqlite3@testing \
#    php84-sysvmsg@testing \
#    php84-sysvsem@testing \
#    php84-sysvshm@testing \
#    php84-tideways_xhprof@testing \
#    php84-tidy@testing \
    php84-tokenizer@testing \
    php84-xml@testing \
    php84-xmlreader@testing \
    php84-xmlwriter@testing \
    php84-zip@testing \
    \
    # use php84-fpm instead of php84-apache
    php84-fpm@testing \
    \
    # i18n
    icu-data-full \
    \
    # PECL extensions
#    php84-pecl-amqp@testing \
#    php84-pecl-apcu@testing \
#    php84-pecl-ast@testing \
#    php84-pecl-couchbase@testing \
#    php84-pecl-event@testing \
#    php84-pecl-igbinary@testing \
#    php84-pecl-imagick@testing \
#    php84-pecl-imagick-dev@testing \
#    php84-pecl-lzf@testing \
#    php84-pecl-mailparse@testing \
#    php84-pecl-maxminddb@testing \
#    php84-pecl-mcrypt@testing \
#    php84-pecl-memcache@testing \
#    php84-pecl-memcached@testing \
#    php84-pecl-mongodb@testing \
#    php84-pecl-msgpack@testing \
#    php84-pecl-oauth@testing \
#    php84-pecl-protobuf@testing \
#    php84-pecl-psr@testing \
#    php84-pecl-rdkafka@testing \
#    php84-pecl-redis@testing \
#    php84-pecl-ssh2@testing \
#    php84-pecl-timezonedb@testing \
#    php84-pecl-uploadprogress@testing \
#    php84-pecl-uploadprogress-doc@testing \
#    php84-pecl-uuid@testing \
#    php84-pecl-vips@testing \
    php84-pecl-xdebug@testing \
#    php84-pecl-xhprof@testing \
#    php84-pecl-xhprof-assets@testing \
#    php84-pecl-yaml@testing \
#    php84-pecl-zstd@testing \
#    php84-pecl-zstd-dev@testing
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
    apk add --no-cache --no-cache  --repository https://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3 && \
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
    sed -i 's|user = nobody|user = www-data|g' /etc/php84/php-fpm.d/www.conf && \
    sed -i 's|group = nobody|group = www-data|g' /etc/php84/php-fpm.d/www.conf && \
    sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php84/php-fpm.d/www.conf && \
    sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php84/php-fpm.d/www.conf && \
    # configure php-fpm to use unix socket
    sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php84/php-fpm.d/www.conf && \
    # update apache timeout for easier debugging
    sed -i 's|^Timeout .*$|Timeout 600|g' /etc/apache2/conf.d/default.conf && \
    # add vhosts to apache
    echo -e "\n# Include the virtual host configurations:\nIncludeOptional /sites/config/vhosts/*.conf" >> /etc/apache2/httpd.conf && \
    # set localhost server name
    sed -i "s|#ServerName .*:80|ServerName localhost:80|g" /etc/apache2/httpd.conf && \
    # update php max execution time for easier debugging
    sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php84/php.ini && \
    # update max upload size
    sed -i 's|^upload_max_filesize = 2M$|upload_max_filesize = 20M|g' /etc/php84/php.ini && \
    # php log everything
    sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php84/php.ini

COPY --chown=root:root include /tmp

RUN \
    # create php aliases
    ln -s /usr/bin/php84 /usr/bin/php && \
    ln -s /usr/sbin/php-fpm84 /usr/sbin/php-fpm && \
    \
    # configure zsh
    mv /tmp/zshrc /etc/zsh/zshrc && \
    # configure xdebug
    mv /tmp/xdebug.ini /etc/php84/conf.d/xdebug.ini && \
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
    mv /tmp/php-spx/spx.ini /etc/php84/conf.d/spx.ini && \
    mv /tmp/php-spx/spx.so /usr/lib/php84/modules/spx.so && \
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
    chown www-data:www-data /sites/

# add mailpit (intercept emails)
COPY --chown=root:root --from=mailpit /mailpit /usr/local/bin/mailpit
RUN chmod +x /usr/local/bin/mailpit && \
    ln -sf /usr/local/bin/mailpit /usr/sbin/sendmail

WORKDIR /sites/

# set entrypoint
ENTRYPOINT ["tini", "-vw"]

# run script
CMD ["/tmp/start.sh"]
