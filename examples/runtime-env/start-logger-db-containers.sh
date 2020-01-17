#!/bin/bash
#

DOCKER_OPTS="-H tcp://52.44.198.132:2376"
REDIS_IMAGE=bitnami/redis:4.0-centos-7
MONGO_IMAGE=bitnami/mongodb:4.0.10

DOCKER="docker $DOCKER_OPTS"
check_recreate_container() {
  local CONTAINER_NAME=$1
  CONTAINER_STATUS=$($DOCKER inspect -f '{{.State.Status}}' ${CONTAINER_NAME} 2>/dev/null)
  if [[ $? == 0 ]]; then
    echo "Container ${CONTAINER_NAME} is already ${CONTAINER_STATUS}   
  "
    if [[ -n "${FORCE}" ]]; then
      echo "Removing container ${CONTAINER_NAME} ..."
      $DOCKER rm -fv ${CONTAINER_NAME}
    else
      read -r -p "Do you want to recreate it? [y/N] " response
      if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
      then
            echo "Removing container ${CONTAINER_NAME} ..."
            $DOCKER rm -fv ${CONTAINER_NAME}
      else
          echo "Continue ..."
      fi
    fi
  fi
}

REDIS_CONTAINER=codefresh-runtime-redis
REDIS_VOLUME=codefresh-runtime-redis
$DOCKER volume create $REDIS_VOLUME
check_recreate_container $REDIS_CONTAINER
$DOCKER run --name $REDIS_CONTAINER -v ${REDIS_VOLUME}:/bitnami/redis -e REDIS_PASSWORD=hoC9szf7NtrU -d -p 6379:6379 $REDIS_IMAGE

MONGO_CONTAINER=codefresh-runtime-mongo
MONGO_VOLUME=codefresh-runtime-mongo
$DOCKER volume create $MONGO_VOLUME
check_recreate_container $MONGO_CONTAINER
$DOCKER $DOCKER_OPT run --name $MONGO_CONTAINER -v ${MONGO_VOLUME}:/bitnami/mongodb -e MONGODB_PASSWORD=mTiXcU2wafr9 -e MONGODB_ROOT_PASSWORD=XT9nmM8dZD -e MONGODB_USERNAME=cfuser -d -p 27017:27017 $MONGO_IMAGE
while true
do
  echo "Creating db user ..."
  sleep 3
  $DOCKER $DOCKER_OPT exec $MONGO_CONTAINER mongo -u root -p XT9nmM8dZD --eval "db.getSiblingDB('codefresh').createUser({user: 'cfuser', pwd: 'mTiXcU2wafr9', roles: ['readWrite']})"
  CREATE_USER_STATUS=$?
  echo CREATE_USER_STATUS=$CREATE_USER_STATUS
  if [[ "$CREATE_USER_STATUS" == 0 || "$CREATE_USER_STATUS" == "252" ]]; then
    echo "user created"
    break
  fi
done