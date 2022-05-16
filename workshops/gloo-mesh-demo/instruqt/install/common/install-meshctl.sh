#!/bin/bash

LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=${GLOO_MESH_VERSION} sh -

# for immediate use
export PATH=$HOME/.gloo-mesh/bin:$PATH

# Add meshctl to PATH
echo "export PATH=$HOME/.gloo-mesh/bin:$PATH"  >> /root/.bashrc