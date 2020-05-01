#!/bin/sh

echo ""
echo "Start container web server..."

echo "domain: $DOMAIN"
echo "document root: $DOCUMENT_ROOT"

# check if we should expose apache to host
if [ -d /docker/etc/ ];
then
    echo "Expose apache to host..."
    sleep 3

    # check if config backup exists
    if [ ! -d /etc/apache2.bak/ ];
    then
        # create config backup
        echo "Expose apache to host - backup container config"
        cp -r /etc/apache2/ /etc/apache2.bak/
    fi

    # check if config exists on host
    if [ -z "$(ls -A /docker/etc/apache2/ 2> /dev/null)" ];
    then
        # config doesn't exist on host
        echo "Expose apache to host - no host config"

        # check if config backup exists
        if [ -d /etc/apache2.bak/ ];
        then
            # restore config from backup
            echo "Expose apache to host - restore config from backup"
            rm /etc/apache2/
            cp -r /etc/apache2.bak/ /etc/apache2/
        fi

        # copy config to host
        echo "Expose apache to host - copy config to host"
        cp -r /etc/apache2/ /docker/etc/
    else
        echo "Expose apache to host - config exists on host"
    fi

    # create symbolic link so host config is used
    echo "Expose apache to host - create symlink"
    rm -rf /etc/apache2/
    ln -s /docker/etc/apache2 /etc/apache2

    echo "Expose apache to host - OK"

    if [ ! -e /etc/ssl/apache2/$DOMAIN.pem ];
    then
        echo "Generate self-signed SSL certificate for $DOMAIN..."

        # generate self-signed SSL certificate
        openssl req -new -x509 -key /etc/ssl/apache2/server.key -out /etc/ssl/apache2/$DOMAIN.pem -days 3650 -subj /CN=$DOMAIN

        # use SSL certificate
        sed -i "s|SSLCertificateFile .*|SSLCertificateFile /etc/ssl/apache2/$DOMAIN.pem|g" /etc/apache2/conf.d/ssl.conf

        echo "Generate self-signed SSL certificate for $DOMAIN - OK"
    fi

    echo "Configure apache for domain..."

    # set document root dir
    sed -i "s|/var/www/localhost/htdocs|/var/www/site$DOCUMENT_ROOT|g" /etc/apache2/httpd.conf

    # set SSL document root dir
    sed -i "s|DocumentRoot \".*\"|DocumentRoot \"/var/www/site$DOCUMENT_ROOT\"|g" /etc/apache2/conf.d/ssl.conf

    sed -i "s|#ServerName .*:80|ServerName $DOMAIN:80|g" /etc/apache2/httpd.conf
    sed -i "s|ServerName .*:443|ServerName $DOMAIN:443|g" /etc/apache2/conf.d/ssl.conf

    echo "Configure apache for domain - OK"

    echo "Expose php to host..."
    sleep 3

    # check if config backup exists
    if [ ! -d /etc/php7.bak/ ];
    then
        # create config backup
        echo "Expose php to host - backup container config"
        cp -r /etc/php7/ /etc/php7.bak/
    fi

    # check if php config exists on host
    if [ -z "$(ls -A /docker/etc/php7/ 2> /dev/null)" ];
    then
        # config doesn't exist on host
        echo "Expose php to host - no host config"

        # check if config backup exists
        if [ -d /etc/php7.bak/ ];
        then
            # restore config from backup
            echo "Expose php to host - restore config from backup"
            rm /etc/php7/
            cp -r /etc/php7.bak/ /etc/php7/
        fi

        # copy config to host
        echo "Expose php to host - copy config to host"
        cp -r /etc/php7/ /docker/etc/
    else
        echo "Expose php to host - config exists on host"
    fi

    # create symbolic link so host config is used
    echo "Expose php to host - create symlink"
    rm -rf /etc/php7/
    ln -s /docker/etc/php7 /etc/php7

    echo "Expose php to host - OK"
fi

# clean log files
truncate -s 0 /var/log/apache2/access.log
truncate -s 0 /var/log/apache2/error.log
truncate -s 0 /var/log/apache2/ssl_request.log
truncate -s 0 /var/log/apache2/xdebug.log

# allow xdebug to write to it
chmod 666 /var/log/apache2/xdebug.log

# start php-fpm
php-fpm7

# sleep
sleep 2

# check if php-fpm is running
if pgrep -x php-fpm7 > /dev/null
then
    echo "-----------------------------------------------"
    echo "Start php-fpm - OK"
else
    echo "Start php-fpm - FAILED"
    exit
fi

echo "-----------------------------------------------"

# start apache
httpd -k start

# check if apache is running
if pgrep -x httpd > /dev/null
then
    echo "Start container web server - OK - ready for connections"
else
    echo "Start container web server - FAILED"
    exit
fi

stop_container()
{
    echo ""
    echo "Stop container web server... - received SIGTERM signal"
    echo "Stop container web server - OK"
    exit
}

# catch termination signals
# https://unix.stackexchange.com/questions/317492/list-of-kill-signals
trap stop_container SIGTERM

restart_processes()
{
    sleep 0.5

    # test php-fpm config
    if php-fpm7 -t
    then
        # restart php-fpm
        echo "Restart php-fpm..."
        httpd -k restart

        # check if php-fpm is running
        if pgrep -x php-fpm7 > /dev/null
        then
            echo "Restart php-fpm - OK"
        else
            echo "Restart php-fpm - FAILED"
        fi
    else
        echo "Restart php-fpm - FAILED - syntax error"
    fi

    # test apache config
    if httpd -t
    then
        # restart apache
        echo "Restart apache..."
        httpd -k restart

        # check if apache is running
        if pgrep -x httpd > /dev/null
        then
            echo "Restart apache - OK"
        else
            echo "Restart apache - FAILED"
        fi
    else
        echo "Restart apache - FAILED - syntax error"
    fi
}

# infinite loop, will only stop on termination signal
while true; do
    # restart apache and php-fpm if any file in /etc/apache2 or /etc/php7 changes
    inotifywait --quiet --event modify,create,delete --timeout 3 --recursive /etc/apache2/ /etc/php7/ && restart_processes
done
