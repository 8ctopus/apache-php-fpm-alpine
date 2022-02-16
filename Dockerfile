FROM alpine:3.15.0

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

ENV DOMAIN localhost
ENV DOCUMENT_ROOT /public

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
    # use php8-fpm instead of php8-apache2
    php8-fpm \
    php8-bcmath \
    php8-common \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-fileinfo \
    php8-gettext \
    php8-json \
    php8-mbstring \
    php8-mysqli \
    php8-opcache \
    php8-openssl \
    php8-pdo \
    php8-pdo_mysql \
    php8-pdo_sqlite \
    php8-posix \
    php8-session \
    php8-simplexml \
    php8-sodium \
    php8-tokenizer \
    php8-xml \
    php8-xmlwriter \
    php8-zip

# install xdebug
RUN apk add \
    php8-pecl-xdebug

# configure xdebug
ADD --chown=root:root include/xdebug.ini /etc/php8/conf.d/xdebug.ini

# install composer
RUN apk add \
    composer

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

# enable mod rewrite
RUN sed -i 's|#LoadModule rewrite_module modules/mod_rewrite.so|LoadModule rewrite_module modules/mod_rewrite.so|g' /etc/apache2/httpd.conf

# authorize all directives in .htaccess
RUN sed -i 's|    AllowOverride None|    AllowOverride All|g' /etc/apache2/httpd.conf

# change log files location
RUN mkdir -p /var/log/apache2
RUN sed -i 's| logs/error.log| /var/log/apache2/error.log|g' /etc/apache2/httpd.conf
RUN sed -i 's| logs/access.log| /var/log/apache2/access.log|g' /etc/apache2/httpd.conf

# change SSL log files location
RUN sed -i 's|ErrorLog logs/ssl_error.log|ErrorLog /var/log/apache2/error.log|g' /etc/apache2/conf.d/ssl.conf
RUN sed -i 's|TransferLog logs/ssl_access.log|TransferLog /var/log/apache2/access.log|g' /etc/apache2/conf.d/ssl.conf

# switch from mpm_prefork to mpm_event
RUN sed -i 's|LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule mpm_event_module modules/mod_mpm_event.so|LoadModule mpm_event_module modules/mod_mpm_event.so|g' /etc/apache2/httpd.conf

# enable important apache modules
RUN sed -i 's|#LoadModule deflate_module modules/mod_deflate.so|LoadModule deflate_module modules/mod_deflate.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule expires_module modules/mod_expires.so|LoadModule expires_module modules/mod_expires.so|g' /etc/apache2/httpd.conf
RUN sed -i 's|#LoadModule ext_filter_module modules/mod_ext_filter.so|LoadModule ext_filter_module modules/mod_ext_filter.so|g' /etc/apache2/httpd.conf

# authorize all changes in htaccess
RUN sed -i 's|Options Indexes FollowSymLinks|Options All|g' /etc/apache2/httpd.conf

# configure php-fpm to run as www-data
RUN sed -i 's|user = nobody|user = www-data|g' /etc/php8/php-fpm.d/www.conf
RUN sed -i 's|group = nobody|group = www-data|g' /etc/php8/php-fpm.d/www.conf
RUN sed -i 's|;listen.owner = nobody|listen.owner = www-data|g' /etc/php8/php-fpm.d/www.conf
RUN sed -i 's|;listen.group = group|listen.group = www-data|g' /etc/php8/php-fpm.d/www.conf

# configure php-fpm to use unix socket
RUN sed -i 's|listen = 127.0.0.1:9000|listen = /var/run/php-fpm8.sock|g' /etc/php8/php-fpm.d/www.conf

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
RUN sed -i 's|^max_execution_time .*$|max_execution_time = 600|g' /etc/php8/php.ini

# php log everything
RUN sed -i 's|^error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT$|error_reporting = E_ALL|g' /etc/php8/php.ini

# add php-spx
ADD --chown=root:root include/php-spx/assets/ /usr/share/misc/php-spx/assets/
ADD --chown=root:root include/php-spx/spx.so /usr/lib/php8/modules/spx.so
ADD --chown=root:root include/php-spx/spx.ini /etc/php8/conf.d/spx.ini

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
