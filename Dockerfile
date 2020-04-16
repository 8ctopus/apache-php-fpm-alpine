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

# install php
RUN apk add \
    php7-apache2 \
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

# configure xdebug
ADD --chown=root:root include/xdebug.ini /etc/php7/conf.d/xdebug.ini

# install composer
RUN apk add \
    composer

# install apache
RUN apk add \
    apache2 \
    apache2-ssl

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

# add site test page
ADD --chown=root:root include/index.php /var/www/site/index.php

# add entry point script
ADD --chown=root:root include/start.sh /start.sh

# make entry point script executable
RUN chmod +x /start.sh

# set working dir
WORKDIR /var/www/site/

ENTRYPOINT ["/start.sh"]
