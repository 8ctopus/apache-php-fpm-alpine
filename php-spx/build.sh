VERSION="3.18.4"

# https://stackoverflow.com/a/20434740/10126479
DIR="$( cd "$( dirname "$0" )" && pwd )"

# build for alpine
DOCKER_BUILDKIT=1 docker build --no-cache --file $DIR/Dockerfile-alpine --build-arg "VERSION=$VERSION" --output type=local,dest=$DIR/lib .

cp $DIR/lib/alpine-$VERSION/spx.so $DIR/../include/php-spx/
