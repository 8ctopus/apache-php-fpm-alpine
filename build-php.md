# build php from source

## credits

    https://php.watch/articles/compile-php-ubuntu

## instructions

    apk add git build-base autoconf bison re2c pkgconfig libxml2-dev sqlite-dev
    git clone https://github.com/php/php-src.git --depth=1000
    cd php-src
    git checkout php-8.3.0RC4
    ./buildconf
    ./configure
    make -j $(nproc)
    cd sapi
    ./php -v
