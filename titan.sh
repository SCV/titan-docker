#!/bin/bash

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

PWD=`pwd`
DIR=$(dirname `readlink -f $0`)

cd $DIR

NAME=$1
VERSION=`utils/get-titan-version.sh $2`

docker images | awk "BEGIN { code = 1 } ; { if (\$1 == \"titan\" && \$2 == \"$VERSION\") code = 0 } ; END { exit code }"

if [ $? -ne 0 ]; then
  utils/create-image.sh -t $VERSION
  docker build -t titan:$VERSION . && rm Dockerfile
fi

if [ "$NAME" == "-" ]; then
  NAME=
fi

if [ -z $NAME ]; then
  if [ -z $TITAN_DOCKER_MOUNT ]; then
    docker run --rm --net=none -t -i titan:$VERSION
  else
    docker run --rm --net=none -v `readlink -f $TITAN_DOCKER_MOUNT`:/mnt -t -i titan:$VERSION
  fi
else
  docker ps -a | awk "BEGIN { code = 1 } ; { if (\$2 == \"titan:$VERSION\" && \$NF == \"$NAME\") code = 0 } ; END { exit code }"
  if [ $? -eq 0 ]; then
    docker start -i $NAME
  else
    if [ -z $TITAN_DOCKER_MOUNT ]; then
      docker run --net=none --name $NAME -t -i titan:$VERSION
    else
      docker run --net=none --name $NAME -v `readlink -f $TITAN_DOCKER_MOUNT`:/mnt -t -i titan:$VERSION
    fi
  fi
fi

cd $PWD
