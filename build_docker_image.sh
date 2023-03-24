#!/bin/bash

source ./env_variables.conf

# build 
docker build -t $IMG_NAME .
