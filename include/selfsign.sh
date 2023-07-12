#!/bin/sh

EXPECTED_CHECKSUM="$(php -r 'copy("https://github.com/8ctopus/self-sign/raw/master/bin/selfsign.sha256", "php://stdout");')"
php -r "copy('https://github.com/8ctopus/self-sign/raw/master/bin/selfsign.phar', 'selfsign.phar');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha256', 'selfsign.phar');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo 'ERROR: Invalid checksum'
    rm selfsign.phar
    exit 1
fi

exit 0
