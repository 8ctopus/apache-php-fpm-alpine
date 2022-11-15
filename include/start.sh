#!/bin/sh

echo ""
echo "Start container web server..."

# check if we should expose apache to host
# /docker/etc/ must be set in docker-compose.yml
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
            rm /etc/apache2/ 2> /dev/null
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
    rm -rf /etc/apache2/ 2> /dev/null
    ln -s /docker/etc/apache2 /etc/apache2

    echo "Expose apache to host - OK"
fi

# check for existing certificate authority
if [ ! -e /sites/config/ssl/certificate_authority.pem ];
then
    # https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate
    echo "Generate certificate authority..."

    # generate certificate authority private key
    openssl genrsa -out /sites/config/ssl/certificate_authority.key 2048 2> /dev/null

    # generate certificate authority certificate
    # to read content openssl x590 -in /sites/config/ssl/certificate_authority.pem -noout -text
    openssl req -new -x509 -nodes -key /sites/config/ssl/certificate_authority.key -sha256 -days 825 -out /sites/config/ssl/certificate_authority.pem -subj "/C=RU/O=8ctopus" 2> /dev/null

    echo "Generate certificate authority - OK"
fi

# check if localhost ssl certificate exists
if [ ! -e /sites/localhost/ssl/certificate.pem ];
then
    # create certificate
    /sites/generate-ssl.sh localhost localhost

    # use certificate
    sed -i "s|SSLCertificateFile .*|SSLCertificateFile /sites/localhost/ssl/certificate.pem|g" /etc/apache2/conf.d/ssl.conf
    sed -i "s|SSLCertificateKeyFile .*|SSLCertificateKeyFile /sites/localhost/ssl/private.key|g" /etc/apache2/conf.d/ssl.conf
fi

# check if test site exists
if [ -d /sites/test/ ];
then
    # check if test.com ssl certificate exists
    if [ ! -e /sites/test/ssl/certificate.pem ];
    then
        # create certificate
        /sites/generate-ssl.sh test test.com
    fi
fi

# check if we should expose php to host
if [ -d /docker/etc/ ];
then
    echo "Expose php to host..."
    sleep 3

    # check if config backup exists
    if [ ! -d /etc/php82.bak/ ];
    then
        # create config backup
        echo "Expose php to host - backup container config"
        cp -r /etc/php82/ /etc/php82.bak/
    fi

    # check if php config exists on host
    if [ -z "$(ls -A /docker/etc/php82/ 2> /dev/null)" ];
    then
        # config doesn't exist on host
        echo "Expose php to host - no host config"

        # check if config backup exists
        if [ -d /etc/php82.bak/ ];
        then
            # restore config from backup
            echo "Expose php to host - restore config from backup"
            rm /etc/php82/ 2> /dev/null
            cp -r /etc/php82.bak/ /etc/php8/
        fi

        # copy config to host
        echo "Expose php to host - copy config to host"
        cp -r /etc/php82/ /docker/etc/
    else
        echo "Expose php to host - config exists on host"
    fi

    # create symbolic link so host config is used
    echo "Expose php to host - create symlink"
    rm -rf /etc/php82/ 2> /dev/null
    ln -s /docker/etc/php82 /etc/php82

    echo "Expose php to host - OK"
fi

# clean log files
#truncate -s 0 /var/log/apache2/access_log 2> /dev/null
#truncate -s 0 /var/log/apache2/error_log 2> /dev/null
#truncate -s 0 /var/log/apache2/ssl_request.log 2> /dev/null
#truncate -s 0 /var/log/apache2/xdebug.log 2> /dev/null

# allow xdebug to write to log file
#chmod 666 /var/log/apache2/xdebug.log 2> /dev/null

# start php-fpm
php-fpm82

# sleep
sleep 2

# check if php-fpm is running
if pgrep -x php-fpm82 > /dev/null
then
    echo "Start php-fpm - OK"
else
    echo "Start php-fpm - FAILED"
    exit
fi

echo "-------------------------------------------------------"

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

echo "-------------------------------------------------------"

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
    if php-fpm82 -t
    then
        # restart php-fpm
        echo "Restart php-fpm..."
        killall php-fpm82 > /dev/null
        php-fpm82

        # check if php-fpm is running
        if pgrep -x php-fpm82 > /dev/null
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
    # restart apache and php-fpm if any file in /etc/apache2 or /etc/php82 changes
    inotifywait --quiet --event modify,create,delete --timeout 3 --recursive /etc/apache2/ /etc/php82/ /sites/config/ && restart_processes
done
