***Using Cilium in Kind***

Follow these steps to get a KinD cluster up and running and then proceed to install the cilium CNI and CLI

1. kubectl apply -f [gitlocation]
2. curl cilium cli download
3. cilium install
4. cilium status
5. kubectl get pods -A (to verify coreDNS pods are up and running) 
