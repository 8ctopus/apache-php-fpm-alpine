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

# check if sites config does not exist
# it happens when docker-compose.yml mounts sites dir on the host
if [ ! -d /sites/config/ ];
then
    # copy default config from the backup
    cp -r /sites.bak/config/ /sites/config/

    # check if localhost does not exist
    if [ ! -d /sites/localhost/ ];
    then
        # copy localhost from the backup
        cp -rp /sites.bak/localhost/ /sites/localhost/
    fi

    # check if test does not exist
    if [ ! -d /sites/test/ ];
    then
        # copy test from the backup
        cp -rp /sites.bak/test/ /sites/test/
    fi
fi

# check if SSL certificate authority does not exist
if [ ! -e /sites/config/ssl/certificate_authority.pem ];
then
    # https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate
    echo "Generate SSL certificate authority..."

    selfsign authority /sites/config/ssl

    echo "Generate SSL certificate authority - OK"
fi

# check if localhost config exists
if [ -d /sites/localhost/ ];
then
    # check if localhost ssl certificate exists
    if [ ! -e /sites/localhost/ssl/certificate.pem ];
    then
        # create certificate
        selfsign certificate /sites/localhost/ssl localhost /sites/config/ssl
    fi
fi

# check if test.com config exists
if [ -d /sites/test/ ];
then
    # check if test.com ssl certificate exists
    if [ ! -e /sites/test/ssl/certificate.pem ];
    then
        # create certificate
        selfsign certificate /sites/test/ssl test.com,www.test.com /sites/config/ssl
    fi
fi

# check if we should expose php to host
if [ -d /docker/etc/ ];
then
    echo "Expose php to host..."
    sleep 3

    # check if config backup exists
    if [ ! -d /etc/php84.bak/ ];
    then
        # create config backup
        echo "Expose php to host - backup container config"
        cp -r /etc/php84/ /etc/php84.bak/
    fi

    # check if php config exists on host
    if [ -z "$(ls -A /docker/etc/php84/ 2> /dev/null)" ];
    then
        # config doesn't exist on host
        echo "Expose php to host - no host config"

        # check if config backup exists
        if [ -d /etc/php84.bak/ ];
        then
            # restore config from backup
            echo "Expose php to host - restore config from backup"
            rm /etc/php84/ 2> /dev/null
            cp -r /etc/php84.bak/ /etc/php8/
        fi

        # copy config to host
        echo "Expose php to host - copy config to host"
        cp -r /etc/php84/ /docker/etc/
    else
        echo "Expose php to host - config exists on host"
    fi

    # create symbolic link so host config is used
    echo "Expose php to host - create symlink"
    rm -rf /etc/php84/ 2> /dev/null
    ln -s /docker/etc/php84 /etc/php84

    echo "Expose php to host - OK"
fi

# clean log files
truncate -s 0 /sites/*/logs/access_log 2> /dev/null
truncate -s 0 /sites/*/logs/error_log 2> /dev/null
truncate -s 0 /var/log/ssl_request.log 2> /dev/null
truncate -s 0 /sites/localhost/logs/xdebug.log 2> /dev/null

# allow xdebug to write to log file
chmod 666 /var/log/xdebug.log 2> /dev/null

echo "Start mailpit"
mailpit 1> /dev/null &

# start php-fpm
php-fpm84

# sleep
sleep 2

# check if php-fpm is running
if pgrep -x php-fpm84 > /dev/null
then
    echo "Start php-fpm - OK"
else
    echo "Start php-fpm - FAILED"
    exit 1
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
    exit 1
fi

echo "-------------------------------------------------------"

stop_container()
{
    echo ""
    echo "Stop container web server... - received SIGTERM signal"
    echo "Stop container web server - OK"
    exit 0
}

# catch termination signals
# https://unix.stackexchange.com/questions/317492/list-of-kill-signals
trap stop_container SIGTERM


restart_processes()
{
    sleep 0.5

    # test php-fpm config
    if php-fpm84 -t
    then
        # restart php-fpm
        echo "Restart php-fpm..."
        killall php-fpm84 > /dev/null
        php-fpm84

        # check if php-fpm is running
        if pgrep -x php-fpm84 > /dev/null
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

# infinite loop, will only stop on termination signal or deletion of sites/config
while [ -d /sites/config/ ]
do
    # restart apache and php-fpm if any file in /etc/apache2 or /etc/php84 changes
    inotifywait --quiet --event modify,create,delete --timeout 3 --recursive /etc/apache2/ /etc/php84/ /sites/config/ && restart_processes
done
