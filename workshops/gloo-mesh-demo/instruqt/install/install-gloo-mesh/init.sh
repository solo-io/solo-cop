#!/bin/bash

# LOCAL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Enable bash completion for kubectl
# echo "source /usr/share/bash-completion/bash_completion" >> /root/.bashrc
# echo "complete -F __start_kubectl k" >> /root/.bashrc

# download gloo mesh helm charts
helm repo add gloo-mesh-enterprise https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-enterprise
helm repo add gloo-mesh-agent https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-agent
helm repo update

# create namespaces
kubectl create namespace gloo-mesh
kubectl create namespace gloo-mesh-addons
kubectl label namespace gloo-mesh-addons istio-injection=enabled

# write the env file to bashrc (its a bit hacky)
cat $LOCAL_DIR/../env.sh | grep "export" | tail -n +2 >> /root/.bashrc