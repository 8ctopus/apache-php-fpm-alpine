FROM alpine:3.11

# expose ports
EXPOSE 80/tcp
EXPOSE 443/tcp

# install console tools
RUN apk add \
    inotify-tools \
    nano

# install and configure zsh
RUN apk add \
    zsh \
    zsh-vcs

ADD --chown=root:root include/zshrc /etc/zsh/zshrc

# install openrc
RUN apk add \
    openrc

# install php
RUN apk add \
    # use php7-fpm instead of php7-apache2
    php7-fpm \
    php7-bcmath \
    php7-common \
    php7-ctype \
    php7-dom \
    php7-fileinfo \
    php7-json \
    php7-mbstring \
    php7-mysqli \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-session \
    php7-tokenizer \
    php7-xml \
    php7-xmlwriter

# install xdebug
RUN apk add \
    php7-pecl-xdebug

# hack to start services
RUN rc-status; \
    rc-update add php-fpm7; \
    touch /run/openrc/softlevel

# necessary for services to be started
VOLUME ["/sys/fs/cgroup"]

# configure xdebug
ADD --chown=root:root include/xdebug.ini /etc/php7/conf.d/xdebug.ini

# install composer
RUN apk add \
    composer

# install apache
RUN apk add \
    apache2 \
    apache2-ssl \
    apache2-proxy

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

# switch to php-fpm
RUN sed -i 's|^DocumentRoot|ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/localhost/htdocs/$1\n\nDocumentRoot|g' /etc/apache2/httpd.conf

# update directory index to add php files
RUN sed -i 's|DirectoryIndex index.html|DirectoryIndex index.php index.html|g' /etc/apache2/httpd.conf

# add site test page
ADD --chown=root:root include/index.php /var/www/site/index.php

# add entry point script
ADD --chown=root:root include/start.sh /start.sh

# make entry point script executable
RUN chmod +x /start.sh

# set working dir
WORKDIR /var/www/site/

ENTRYPOINT ["/start.sh"]
