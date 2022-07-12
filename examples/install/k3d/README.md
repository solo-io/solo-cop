# Install using K3d

# Prerequisites
* Docker
* k3d (version v5.4.4)

If using MacOS + Homebrew:
```
brew install k3d
```

# Deploy a single k3d cluster
```
create-k3d-cluster <name> </path/to/k3d/config>
```

# Using Install Script
Installs 3 clusters using k3d
```
./install.sh
```

## Ports
Exposed ports via docker and servicelb. This is to allow your local computer access the ingress load balancers. Within the docker network they are still only available on 443 and 80.

* mgmt cluster port 8090:8090 and 8200:8200
* cluster1 cluster port 8080:80 and 8443:443
* cluster2 cluster port 8081:80 and 8444:443


## Teardown
```
./teardown.sh
```