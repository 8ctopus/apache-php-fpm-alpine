#!/bin/sh

EXPECTED_CHECKSUM="$(php -r 'copy("https://github.com/8ctopus/self-sign/releases/download/0.1.8/selfsign.sha256", "php://stdout");')"
#echo $EXPECTED_CHECKSUM
php -r "copy('https://github.com/8ctopus/self-sign/releases/download/0.1.8/selfsign.phar', '/selfsign.phar');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha256', '/selfsign.phar');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    echo 'ERROR: Invalid checksum'
    rm /selfsign.phar
    exit 1
else
    exit 0
fi
