#!/bin/bash

source ./env_variables.conf

# ensure image is build first
source ./build_docker_image.sh

# then push
#docker push $IMG_NAME
