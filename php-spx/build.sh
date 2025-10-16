VERSION="3.22.2"

# https://stackoverflow.com/a/20434740/10126479
DIR="$( cd "$( dirname "$0" )" && pwd )"

# build for alpine
DOCKER_BUILDKIT=1 docker build --no-cache --file $DIR/Dockerfile --build-arg VERSION=$VERSION --output type=local,dest=$DIR .

cp $DIR/spx.so $DIR/../include/php-spx/
