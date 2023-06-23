#!/bin/bash

delete-k3d-cluster(){
  name=$1

  network=k3d-cluster-network
  k3d cluster delete $name

  # because we renamed them we need to delete the names
  kubectl config delete-cluster $name > /dev/null 2>&1 || true 
  kubectl config delete-user $name > /dev/null 2>&1 || true
  kubectl config delete-context $name > /dev/null 2>&1 || true

  docker network rm $network > /dev/null 2>&1 || true
}

delete-k3d-cluster $CLUSTER1
