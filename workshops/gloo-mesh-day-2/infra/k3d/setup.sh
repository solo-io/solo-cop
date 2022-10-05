#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# docker network
network=gloo-mesh-network

# create docker network if it does not exist
docker network create $network > /dev/null 2>&1 || true

create_cluster(){
  name=$1
  config=$2
  region=$3
  zone=$4

  if [ -z "$3" ]; then
    region=us-east-1
  fi

  if [ -z "$4" ]; then
    zone=us-east-1a
  fi

  k3d cluster create --wait --config $config

  # remove existing context if they exist
  kubectl config delete-cluster $name > /dev/null 2>&1 || true
  kubectl config delete-user $name > /dev/null 2>&1 || true
  kubectl config delete-context $name > /dev/null 2>&1 || true

  kubectl config rename-context k3d-$name $name
}

create_cluster $MGMT $LOCAL_DIR/mgmt.yaml
create_cluster $CLUSTER1 $LOCAL_DIR/cluster1.yaml us-east-1 us-east-1c
