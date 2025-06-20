ARG VERSION=latest
FROM alpine:${VERSION} AS build

# update repositories to edge
RUN printf "https://dl-cdn.alpinelinux.org/alpine/edge/main\nhttps://dl-cdn.alpinelinux.org/alpine/edge/community\n" > /etc/apk/repositories

# add testing repository
RUN printf "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing\n" >> /etc/apk/repositories

# update apk repositories
RUN apk update

# upgrade all
RUN apk upgrade

# add c build tools
RUN apk add build-base

# add dev libraries
RUN apk add \
    php84-dev@testing \
    zlib-dev@testing

# add git
RUN apk add git

# clone php-spx
RUN git clone --depth 50 https://github.com/NoiseByNorthwest/php-spx.git

# set workdir
WORKDIR /php-spx

# checkout release
RUN git checkout tags/v0.4.18

# fix ./configure "Cannot find php-config. Please use --with-php-config=PATH"
RUN ln -s /usr/bin/php-config84 /usr/bin/php-config

# build php-spx
RUN phpize84
RUN ./configure
RUN make

# start again with a new image
FROM scratch

# get version
ARG VERSION

# copy spx module from alpine image to the scratch image so files can be copied back to host
COPY --from=build /php-spx/modules/spx.so spx.so
