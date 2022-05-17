#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# install keycloak
$LOCAL_DIR/../../install/keycloak/setup.sh