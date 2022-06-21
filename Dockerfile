FROM alpine:3.16.0

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

ENV DOMAIN localhost
ENV DOCUMENT_ROOT /public

# add edge community packages for php 8.1
RUN echo "@edge https://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@edge https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

# update apk repositories
RUN apk update

# upgrade all
RUN apk upgrade

# install console tools
RUN apk add \
    inotify-tools

# install zsh
RUN apk add \
    zsh \
    zsh-vcs

# configure zsh
ADD --chown=root:root include/zshrc /etc/zsh/zshrc

# install php
RUN apk add \
    php81@edge \
    php81-bcmath@edge \
    php81-common@edge \
    php81-ctype@edge \
    php81-curl@edge \
    php81-dom@edge \
    php81-fileinfo@edge \
    php81-gd@edge \
    php81-gettext@edge \
    php81-json@edge \
    php81-iconv@edge \
    php81-imap@edge \
    php81-mbstring@edge \
    php81-mysqli@edge \
    php81-opcache@edge \
    php81-openssl@edge \
    php81-pdo@edge \
    php81-pdo_mysql@edge \
    php81-pdo_sqlite@edge \
    php81-phar@edge \
    php81-posix@edge \
    php81-session@edge \
    php81-simplexml@edge \
    php81-sodium@edge \
    php81-tokenizer@edge \
    php81-xml@edge \
    php81-xmlwriter@edge \
    php81-zip@edge

# use php81-fpm instead of php81-apache2
RUN apk add php81-fpm@edge

# i18n
RUN apk add \
    php81-intl@edge \
    icu-data-full@edge

# fix php iconv
# https://stackoverflow.com/questions/70046717/iconv-error-when-running-statamic-laravel-seo-pro-plugin-with-phpfpm-alpine
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ gnu-libiconv=1.15-r3
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# add symbolic link to php
RUN ln -s /usr/bin/php81 /usr/bin/php

# install xdebug
RUN apk add php81-pecl-xdebug@edge

# configure xdebug
ADD --chown=root:root include/xdebug.ini /etc/php81/conf.d/xdebug.ini

RUN mkdir /var/log/apache2/

# install composer
#RUN apk add \
#    composer

# add composer script
ADD --chown=root:root include/composer.sh /tmp/composer.sh

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
RUN sed -i 's| logs/error.log| /var/log/apache2/error_log|g' /etc/apache2/httpd.conf
RUN sed -i 's| logs/access.log| /var/log/apache2/access_log|g' /etc/apache2/httpd.conf

# update SSL log location
RUN sed -i 's|ErrorLog logs/ssl_error.log|ErrorLog /var/log/apache2/error_log|g' /etc/apache2/conf.d/ssl.conf
RUN sed -i 's|TransferLog logs/ssl_access.log|TransferLog /var/log/apache2/access_log|g' /etc/apache2/conf.d/ssl.conf

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
RUN sed -i 's|user = nobody|user = www-data|g' /etc/php81/php-fpm.d/www.conf
RUN sed -i 's|group = nobody|group = www-data|g' /etc/php81/php-fpm.d/www.conf
RUN sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php81/php-fpm.d/www.conf
RUN sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php81/php-fpm.d/www.conf

# configure php-fpm to use unix socket
RUN sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php81/php-fpm.d/www.conf

# switch apache to use php-fpm through proxy
# don't use proxy pass match because it does not support directory indexing
#RUN sed -i 's|^DocumentRoot|ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/localhost/htdocs/$1\n\nDocumentRoot|g' /etc/apache2/httpd.conf

# use set handler to route php requests to php-fpm
RUN sed -i 's|^DocumentRoot|<FilesMatch "\.php$">\n\
    SetHandler "proxy:unix:/var/run/php-fpm8.sock\|fcgi://localhost"\n\
</FilesMatch>\n\nDocumentRoot|g' /etc/apache2/httpd.conf

# update directory index to add php files
RUN sed -i 's|DirectoryIndex index.html|DirectoryIndex index.php index.html|g' /etc/apache2/httpd.conf

# update apache timeout for easier debugging
RUN sed -i 's|^Timeout .*$|Timeout 600|g' /etc/apache2/conf.d/default.conf

# add http authentication support
RUN sed -i 's|^DocumentRoot|<VirtualHost _default_:80>\n    SetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1\n</VirtualHost>\n\nDocumentRoot|g' /etc/apache2/httpd.conf
RUN sed -i 's|<VirtualHost _default_:443>|<VirtualHost _default_:443>\n\nSetEnvIf Authorization "(.*)" HTTP_AUTHORIZATION=$1|g' /etc/apache2/conf.d/ssl.conf

# update php max execution time for easier debugging
RUN sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php81/php.ini

# php log everything
RUN sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php81/php.ini

# add php-spx
ADD --chown=root:root include/php-spx/assets/ /usr/share/misc/php-spx/assets/
ADD --chown=root:root include/php-spx/spx.so /usr/lib/php81/modules/spx.so
ADD --chown=root:root include/php-spx/spx.ini /etc/php81/conf.d/spx.ini

# add test pages to site
ADD --chown=root:root html/public/ /var/www/html$DOCUMENT_ROOT/

# add entry point script
ADD --chown=root:root include/start.sh /tmp/start.sh

# make entry point script executable
RUN chmod +x /tmp/start.sh

# set working dir
WORKDIR /var/www/html/

# set entrypoint
ENTRYPOINT ["/tmp/start.sh"]
