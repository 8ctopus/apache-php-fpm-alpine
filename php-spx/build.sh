# https://stackoverflow.com/a/20434740/10126479
DIR="$( cd "$( dirname "$0" )" && pwd )"

# build for ubuntu 20.04
#DOCKER_BUILDKIT=1 docker build --file $DIR/Dockerfile-ubuntu --build-arg "VERSION=20.04" --output type=local,dest=lib .

# build for alpine 3.15.4
DOCKER_BUILDKIT=1 docker build --file $DIR/Dockerfile-alpine --build-arg "VERSION=3.15.4" --output type=local,dest=$DIR/lib .

# build for alpine edge
DOCKER_BUILDKIT=1 docker build --file $DIR/Dockerfile-alpine --build-arg "VERSION=edge" --output type=local,dest=$DIR/lib .

cp $DIR/lib/alpine-edge/spx.so $DIR/../include/php-spx/
