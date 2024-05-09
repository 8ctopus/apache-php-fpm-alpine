VERSION="3.19.1"

# https://stackoverflow.com/a/20434740/10126479
DIR="$( cd "$( dirname "$0" )" && pwd )"

# build for alpine
DOCKER_BUILDKIT=1 docker build --no-cache --file $DIR/Dockerfile-alpine --build-arg VERSION=$VERSION --output type=local,dest=$DIR .

cp $DIR/spx.so $DIR/../include/php-spx/
