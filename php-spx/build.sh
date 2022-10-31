# https://stackoverflow.com/a/20434740/10126479
DIR="$( cd "$( dirname "$0" )" && pwd )"

# build for alpine edge
DOCKER_BUILDKIT=1 docker build --file $DIR/Dockerfile-alpine --build-arg "VERSION=edge" --output type=local,dest=$DIR/lib .

cp $DIR/lib/alpine-edge/spx.so $DIR/../include/php-spx/
