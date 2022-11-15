FROM alpine:edge
LABEL maintainer="8ctopus <hello@octopuslabs.io>"

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

ENV DOMAIN localhost
ENV DOCUMENT_ROOT /public

# add testing repository
RUN echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# update apk repositories
RUN apk update

# upgrade all
RUN apk upgrade

# install latest certificates for ssl
RUN apk add ca-certificates@testing

# install console tools
RUN apk add \
    inotify-tools@testing

# install zsh
RUN apk add \
    zsh@testing \
    zsh-vcs@testing

# configure zsh
COPY --chown=root:root include/zshrc /etc/zsh/zshrc

# install php
RUN apk add \
    php82@testing \
#    php82-apache2@testing \
    php82-bcmath@testing \
#    php82-brotli@testing \
    php82-bz2@testing \
    php82-calendar@testing \
#    php82-cgi@testing \
    php82-common@testing \
    php82-ctype@testing \
    php82-curl@testing \
#    php82-dba@testing \
#    php82-dbg@testing \
#    php82-dev@testing \
#    php82-doc@testing \
    php82-dom@testing \
#    php82-embed@testing \
#    php82-enchant@testing \
    php82-exif@testing \
#    php82-ffi@testing \
    php82-fileinfo@testing \
    php82-ftp@testing \
    php82-gd@testing \
    php82-gettext@testing \
#    php82-gmp@testing \
    php82-json@testing \
    php82-iconv@testing \
    php82-imap@testing \
    php82-intl@testing \
    php82-ldap@testing \
#    php82-litespeed@testing \
    php82-mbstring@testing \
    php82-mysqli@testing \
#    php82-mysqlnd@testing \
#    php82-odbc@testing \
    php82-opcache@testing \
    php82-openssl@testing \
    php82-pcntl@testing \
    php82-pdo@testing \
    php82-pdo_mysql@testing \
#    php82-pdo_odbc@testing \
#    php82-pdo_pgsql@testing \
    php82-pdo_sqlite@testing \
#    php82-pear@testing \
#    php82-pgsql@testing \
    php82-phar@testing \
#   php82-phpdbg@testing \
    php82-posix@testing \
#    php82-pspell@testing \
    php82-session@testing \
#    php82-shmop@testing \
    php82-simplexml@testing \
#    php82-snmp@testing \
#    php82-soap@testing \+
#    php82-sockets@testing \
    php82-sodium@testing \
    php82-sqlite3@testing \
#    php82-sysvmsg@testing \
#    php82-sysvsem@testing \
#    php82-sysvshm@testing \
#    php82-tideways_xhprof@testing \
#    php82-tidy@testing \
    php82-tokenizer@testing \
    php82-xml@testing \
    php82-xmlreader@testing \
    php82-xmlwriter@testing \
    php82-zip@testing

# use php82-fpm instead of php82-apache
RUN apk add php82-fpm@testing

# i18n
RUN apk add \
    icu-data-full

# fix php iconv
# https://stackoverflow.com/questions/70046717/iconv-error-when-running-statamic-laravel-seo-pro-plugin-with-phpfpm-alpine
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# add symbolic link for php
RUN ln -s /usr/bin/php82 /usr/bin/php

# PECL extensions
RUN apk add \
#    php82-pecl-amqp@testing \
#    php82-pecl-apcu@testing \
#    php82-pecl-ast@testing \
#    php82-pecl-couchbase@testing \
#    php82-pecl-event@testing \
#    php82-pecl-igbinary@testing \
#    php82-pecl-imagick@testing \
#    php82-pecl-imagick-dev@testing \
#    php82-pecl-lzf@testing \
#    php82-pecl-mailparse@testing \
#    php82-pecl-maxminddb@testing \
#    php82-pecl-mcrypt@testing \
#    php82-pecl-memcache@testing \
#    php82-pecl-memcached@testing \
#    php82-pecl-mongodb@testing \
#    php82-pecl-msgpack@testing \
#    php82-pecl-oauth@testing \
#    php82-pecl-protobuf@testing \
#    php82-pecl-psr@testing \
#    php82-pecl-rdkafka@testing \
#    php82-pecl-redis@testing \
#    php82-pecl-ssh2@testing \
#    php82-pecl-timezonedb@testing \
#    php82-pecl-uploadprogress@testing \
#    php82-pecl-uploadprogress-doc@testing \
#    php82-pecl-uuid@testing \
#    php82-pecl-vips@testing \
    php82-pecl-xdebug@testing
#    php82-pecl-xhprof@testing \
#    php82-pecl-xhprof-assets@testing \
#    php82-pecl-yaml@testing \
#    php82-pecl-zstd@testing \
#    php82-pecl-zstd-dev@testing

# configure xdebug
COPY --chown=root:root include/xdebug.ini /etc/php82/conf.d/xdebug.ini

# install composer (currently installs php8.1 which creates a mess, use script approach instead to install)
#RUN apk add \
#    composer@testing

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
    apache2@testing \
    apache2-ssl@testing \
    apache2-proxy@testing

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

# authorize all directives in .htaccess
RUN sed -i 's|    AllowOverride None|    AllowOverride All|g' /etc/apache2/httpd.conf

# authorize all changes from htaccess
RUN sed -i 's|Options Indexes FollowSymLinks|Options All|g' /etc/apache2/httpd.conf

# update error and access logs location
RUN mkdir -p /var/log/apache2
RUN sed -i 's| logs/error.log| /sites/localhost/logs/error_log|g' /etc/apache2/httpd.conf
RUN sed -i 's| logs/access.log| /sites/localhost/logs/access_log|g' /etc/apache2/httpd.conf

# update SSL log location
RUN sed -i 's|ErrorLog logs/ssl_error.log|ErrorLog /sites/localhost/logs/error_log|g' /etc/apache2/conf.d/ssl.conf
RUN sed -i 's|TransferLog logs/ssl_access.log|TransferLog /sites/localhost/logs/access_log|g' /etc/apache2/conf.d/ssl.conf

# update error log logging format
RUN sed -i 's|^<IfModule log_config_module>|<IfModule log_config_module>\n\
    # custom error log format\n\
    ErrorLogFormat "[%t] [%l] [client %a] %M, referer: %{Referer}i"\n\
    \n\
    # log 404 as errors\n\
    LogLevel core:info\n|g' /etc/apache2/httpd.conf

# switch from mpm_prefork to mpm_event
RUN sed -i 's|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|g' /etc/apache2/httpd.conf

# enable important apache modules
RUN sed -i 's|#LoadModule deflate_module modules/mod_deflate.so|LoadModule deflate_module modules/mod_deflate.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule expires_module modules/mod_expires.so|LoadModule expires_module modules/mod_expires.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule ext_filter_module modules/mod_ext_filter.so|LoadModule ext_filter_module modules/mod_ext_filter.so|g' /etc/apache2/httpd.conf

# configure php-fpm to run as www-data
RUN sed -i 's|user = nobody|user = www-data|g' /etc/php82/php-fpm.d/www.conf
RUN sed -i 's|group = nobody|group = www-data|g' /etc/php82/php-fpm.d/www.conf
RUN sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php82/php-fpm.d/www.conf
RUN sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php82/php-fpm.d/www.conf

# configure php-fpm to use unix socket
RUN sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php82/php-fpm.d/www.conf

# switch apache to use php-fpm through proxy
# don't use proxy pass match because it does not support directory indexing
#RUN sed -i 's|^DocumentRoot|ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/localhost/htdocs/$1\n\nDocumentRoot|g' /etc/apache2/httpd.conf

# use set handler to route php requests to php-fpm
RUN sed -i 's|^DocumentRoot|<FilesMatch "\.php$">\n\
    SetHandler "proxy:unix:/var/run/php-fpm8.sock\|fcgi://localhost"\n\
</FilesMatch>\n\nDocumentRoot|g' /etc/apache2/httpd.conf

# update directory index to support php files
RUN sed -i 's|DirectoryIndex index.html|DirectoryIndex index.php index.html|g' /etc/apache2/httpd.conf

# update apache timeout for easier debugging
RUN sed -i 's|^Timeout .*$|Timeout 600|g' /etc/apache2/conf.d/default.conf

# add http authentication support
RUN sed -i 's|^DocumentRoot|<VirtualHost _default_:80>\n    SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1\n</VirtualHost>\n\nDocumentRoot|g' /etc/apache2/httpd.conf
RUN sed -i 's|<VirtualHost _default_:443>|<VirtualHost _default_:443>\n\nSetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1|g' /etc/apache2/conf.d/ssl.conf

# add support for vhosts to apache
RUN echo -e "\n# Include the virtual host configurations:\nIncludeOptional /sites/config/vhosts/*.conf" >> /etc/apache2/httpd.conf

# set localhost document root dir
RUN sed -i "s|/var/www/localhost/htdocs|/sites/localhost/html$DOCUMENT_ROOT|g" /etc/apache2/httpd.conf

# set localhost document root dir for SSL
RUN sed -i "s|DocumentRoot \".*\"|DocumentRoot \"/sites/localhost/html$DOCUMENT_ROOT\"|g" /etc/apache2/conf.d/ssl.conf

# set localhost server name
RUN sed -i "s|#ServerName .*:80|ServerName localhost:80|g" /etc/apache2/httpd.conf
RUN sed -i "s|ServerName .*:443|ServerName localhost:443|g" /etc/apache2/conf.d/ssl.conf

# update php max execution time for easier debugging
RUN sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php82/php.ini

# php log everything
RUN sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php82/php.ini

# add php-spx
COPY --chown=root:root include/php-spx/assets/ /usr/share/misc/php-spx/assets/
COPY --chown=root:root include/php-spx/spx.so /usr/lib/php82/modules/spx.so
COPY --chown=root:root include/php-spx/spx.ini /etc/php82/conf.d/spx.ini

# add default sites
COPY --chown=root:root include/sites/ /sites/

# add entry point script
COPY --chown=root:root include/start.sh /tmp/start.sh

# make entry point script executable
RUN chmod +x /tmp/start.sh

# set working dir
WORKDIR /sites/

# set entrypoint
ENTRYPOINT ["/tmp/start.sh"]
