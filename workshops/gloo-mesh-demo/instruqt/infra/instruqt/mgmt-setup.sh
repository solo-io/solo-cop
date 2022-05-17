#!/bin/bash

echo "export KUBECONFIG=/root/.kube/mgmt:/root/.kube/cluster1:/root/.kube/cluster2" >> /root/.env
source /root/.env
for i in {1..100}; do
  kubectl --context=$CLUSTER1 label node cluster1 ingress-ready=true topology.kubernetes.io/region=us-east-1 topology.kubernetes.io/zone=us-east-1c && break
  sleep 5
done
for i in {1..100}; do
  kubectl --context=$CLUSTER2 label node cluster2 ingress-ready=true topology.kubernetes.io/region=us-west-2 topology.kubernetes.io/zone=us-west-2a && break
  sleep 5
done
echo 'cd /root' >> /etc/bash.bashrc

# Enable bash completion for kubectl
echo "source /usr/share/bash-completion/bash_completion" >> /etc/bash.bashrc
echo "complete -F __start_kubectl k" >> /etc/bash.bashrc
while [ ! -f /opt/instruqt/bootstrap/host-bootstrap-completed ]
do
    echo "Waiting for Instruqt to finish booting the VM"
    sleep 1
done
mkdir -p /root/files
# Disable IPv6, seems like Instruqt has some issues here so this is to work around it
systemctl stop systemd-resolved && systemctl disable systemd-resolved
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
rm /etc/resolv.conf && cp /run/systemd/resolve/resolv.conf /etc/resolv.conf
cat >>/etc/resolv.conf <<EOF
options single-request
options timeout:1
EOF
#end ipv6

# copy kubeconfig to mgmt
while ! stat /etc/rancher/k3s/k3s.yaml; do sleep 1; done
export LOCAL_IP=$(dig +short $(hostname).$INSTRUQT_PARTICIPANT_ID.svc.cluster.local | grep -v '\.$')
cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/$LOCAL_IP/' | sed 's/default/$HOSTNAME/' | HOSTNAME=$(hostname) envsubst > /tmp/$HOSTNAME
while ! rsync -e "ssh -o StrictHostKeyChecking=no" -v /tmp/$HOSTNAME mgmt.$INSTRUQT_PARTICIPANT_ID.svc.cluster.local:/root/.kube/$HOSTNAME; do sleep 1; done
touch /root/.env

# Setup workshop
/workshop/install/setup.sh

# Used for OIDC  
echo "export EXTERNAL_IP=\$(curl -s -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)" >> /root/.env
echo "export ENDPOINT_HTTPS_GW_CLUSTER1_EXT=cluster1-443-\${INSTRUQT_PARTICIPANT_ID}.env.play.instruqt.com" >> /root/.env
GW1=$(kubectl --context ${CLUSTER1} -n istio-gateways get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].*}'):443
echo "export ENDPOINT_HTTPS_GW_CLUSTER1=$GW1" >> /root/.env