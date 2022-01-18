# Air-gap Installation Image List
This utility scripts the functionality found in the Gloo Mesh Enterprise [documentation](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/installation/airgap_install/).  


## Pre-requisites
The following packages need to be installed.
- wget
- yq
- jq
- docker (for pulling images locally)

This script assumes a *nix environment (Mac OS is fine).

To run the utility, type

```
./get-image-list <version>
```

where **version** is the Gloo Mesh Enterprise version (e.g. 1.1.6).

This will print the list of images to stdout.

## Options
`-p | --pull` - pull the images locally.

### Sample Output

Example output when specifying Gloo Mesh 1.1.1 and pulling images.
```
$ ./get-image-list -p 1.1.1
Finding images for Gloo Mesh Enterprise version 1.1.1

###################################
# Getting enterprise-agent images #
###################################
docker.io/library/redis:6
gcr.io/gloo-mesh/enterprise-agent:1.1.1
quay.io/solo-io/ext-auth-service:0.19.1
soloio/rate-limiter:0.4.3

###################################
# Getting Gloo Mesh images        #
###################################
docker.io/library/redis:5
gcr.io/gloo-mesh/enterprise-networking:1.1.1
gcr.io/gloo-mesh/gloo-mesh-apiserver:1.1.1
gcr.io/gloo-mesh/gloo-mesh-envoy:1.1.1
gcr.io/gloo-mesh/gloo-mesh-ui:1.1.1
gcr.io/gloo-mesh/rbac-webhook:1.1.1
jimmidyson/configmap-reload:v0.5.0
k8s.gcr.io/kube-state-metrics/kube-state-metrics:v1.9.8
prom/pushgateway:v1.3.1
quay.io/prometheus/alertmanager:v0.21.0
quay.io/prometheus/node-exporter:v1.0.1
quay.io/prometheus/prometheus:v2.24.0

Pulling images locally
6: Pulling from library/redis
7d63c13d9b9b: Pull complete 
a2c3b174c5ad: Pull complete 
283a10257b0f: Pull complete 
7a08c63a873a: Pull complete 
0531663a7f55: Pull complete 
9bf50efb265c: Pull complete 
Digest: sha256:a89cb097693dd354de598d279c304a1c73ee550fbfff6d9ee515568e0c749cfe
Status: Downloaded newer image for redis:6
docker.io/library/redis:6
1.1.1: Pulling from gloo-mesh/enterprise-agent
cbdbe7a5bc2a: Already exists 
7f3ca033e25a: Pull complete 
54caff211e6f: Pull complete 
Digest: sha256:efb53b510e2b1a3865bf1be4ee7d4ea55fc1e7ac59c3471c71310c1b8a102568
Status: Downloaded newer image for gcr.io/gloo-mesh/enterprise-agent:1.1.1
gcr.io/gloo-mesh/enterprise-agent:1.1.1
0.19.1: Pulling from solo-io/ext-auth-service
cbdbe7a5bc2a: Already exists 
fa76f39b0844: Pull complete 
a10001c3b60d: Pull complete 
Digest: sha256:134784d932f43ddb616ff11ef8729a543cd87d011b2cf6913ccdc425c95fa017
Status: Downloaded newer image for quay.io/solo-io/ext-auth-service:0.19.1
quay.io/solo-io/ext-auth-service:0.19.1
0.4.3: Pulling from soloio/rate-limiter
cbdbe7a5bc2a: Already exists 
7d18ff99fe48: Pull complete 
d4b20d194827: Pull complete 
Digest: sha256:f69e5fcfa094211e279bf4ea7d70cb58c5caaa63a61fc09dd21fcab60a2811b9
Status: Downloaded newer image for soloio/rate-limiter:0.4.3
docker.io/soloio/rate-limiter:0.4.3
5: Pulling from library/redis
7d63c13d9b9b: Already exists 
a2c3b174c5ad: Already exists 
283a10257b0f: Already exists 
54ac4e97e390: Pull complete 
0d3ede1e63a5: Pull complete 
878bf2d7168d: Pull complete 
Digest: sha256:8217ee751b6a72bc4b3ef757c18aa9619e939d5073d5a26ce2074905385000b0
Status: Downloaded newer image for redis:5
docker.io/library/redis:5
1.1.1: Pulling from gloo-mesh/enterprise-networking
cbdbe7a5bc2a: Already exists 
7f3ca033e25a: Already exists 
cfb54b2a2fe0: Pull complete 
Digest: sha256:16cdece490ceb1057e5cdc286326dc6f35b27e8f4754454aaef871324c670436
Status: Downloaded newer image for gcr.io/gloo-mesh/enterprise-networking:1.1.1
gcr.io/gloo-mesh/enterprise-networking:1.1.1
1.1.1: Pulling from gloo-mesh/gloo-mesh-apiserver
ddad3d7c1e96: Already exists 
4b89462a57ff: Pull complete 
4dfbdaf04265: Pull complete 
Digest: sha256:bff92ddf5051584880ffaee40dbc5d26b90d21987f3a31509dad8f2698a06355
Status: Downloaded newer image for gcr.io/gloo-mesh/gloo-mesh-apiserver:1.1.1
gcr.io/gloo-mesh/gloo-mesh-apiserver:1.1.1
1.1.1: Pulling from gloo-mesh/gloo-mesh-envoy
d519e2592276: Pull complete 
d22d2dfcfa9c: Pull complete 
b3afe92c540b: Pull complete 
9b1603fd8add: Pull complete 
3f1b6a6f0ccf: Pull complete 
e94a07e24e1c: Pull complete 
56aa67ab32be: Pull complete 
002bb97c77a0: Pull complete 
9a1cbceb8f80: Pull complete 
1e815a8c139c: Pull complete 
ae6833fe55fe: Pull complete 
Digest: sha256:8a7dc95971926d3cdc3db55c767eabfd7a5ae83d3a18537b9ae5ad9344d2fd9f
Status: Downloaded newer image for gcr.io/gloo-mesh/gloo-mesh-envoy:1.1.1
gcr.io/gloo-mesh/gloo-mesh-envoy:1.1.1
1.1.1: Pulling from gloo-mesh/gloo-mesh-ui
9aae54b2144e: Already exists 
deb02d0f047e: Already exists 
faa46c06ae12: Already exists 
8bbe2a6a37c5: Already exists 
f9b897942de0: Already exists 
7141e8eb7387: Already exists 
07f5ca76a699: Pull complete 
6377408d6a1f: Pull complete 
2cf79a0a19f8: Pull complete 
aba7e8ebb8b3: Pull complete 
4c9e00b18f6c: Pull complete 
Digest: sha256:49e52b34f473dc4663a7633852ec773c98432ddeffa36fe397b2a7eb14049d92
Status: Downloaded newer image for gcr.io/gloo-mesh/gloo-mesh-ui:1.1.1
gcr.io/gloo-mesh/gloo-mesh-ui:1.1.1
1.1.1: Pulling from gloo-mesh/rbac-webhook
ddad3d7c1e96: Already exists 
4d677d1af76a: Pull complete 
Digest: sha256:78093e385ddb7ae1d7bc1a8d2ced962f55ac8f291f76cf0d6c60529243de35f9
Status: Downloaded newer image for gcr.io/gloo-mesh/rbac-webhook:1.1.1
gcr.io/gloo-mesh/rbac-webhook:1.1.1
v0.5.0: Pulling from jimmidyson/configmap-reload
524791274d4f: Pull complete 
9f29de38ddd8: Pull complete 
Digest: sha256:904d08e9f701d3d8178cb61651dbe8edc5d08dd5895b56bdcac9e5805ea82b52
Status: Downloaded newer image for jimmidyson/configmap-reload:v0.5.0
docker.io/jimmidyson/configmap-reload:v0.5.0
v1.9.8: Pulling from kube-state-metrics/kube-state-metrics
9e4425256ce4: Pull complete 
bdcc4e399703: Pull complete 
Digest: sha256:47d3a12d9da6699a9d95df8aaff235305229ef08203fae3fc1f1d47b2a409f89
Status: Downloaded newer image for k8s.gcr.io/kube-state-metrics/kube-state-metrics:v1.9.8
k8s.gcr.io/kube-state-metrics/kube-state-metrics:v1.9.8
v1.3.1: Pulling from prom/pushgateway
ea97eb0eb3ec: Pull complete 
ec0e9aba71a6: Pull complete 
a10230bb2fe4: Pull complete 
aeb42de723aa: Pull complete 
Digest: sha256:8305a33fb80afe5fd5bb85045ce433aeef1aa3703d70831a50796073dba510bb
Status: Downloaded newer image for prom/pushgateway:v1.3.1
docker.io/prom/pushgateway:v1.3.1
v0.21.0: Pulling from prometheus/alertmanager
0f8c40e1270f: Pull complete 
626a2a3fee8c: Pull complete 
74ad1ee664e6: Pull complete 
addd0e4e1dc5: Pull complete 
012b22e92c79: Pull complete 
518f5393dbbc: Pull complete 
Digest: sha256:24a5204b418e8fa0214cfb628486749003b039c279c56b5bddb5b10cd100d926
Status: Downloaded newer image for quay.io/prometheus/alertmanager:v0.21.0
quay.io/prometheus/alertmanager:v0.21.0
v1.0.1: Pulling from prometheus/node-exporter
86fa074c6765: Pull complete 
ed1cd1c6cd7a: Pull complete 
ff1bb132ce7b: Pull complete 
Digest: sha256:cf66a6bbd573fd819ea09c72e21b528e9252d58d01ae13564a29749de1e48e0f
Status: Downloaded newer image for quay.io/prometheus/node-exporter:v1.0.1
quay.io/prometheus/node-exporter:v1.0.1
v2.24.0: Pulling from prometheus/prometheus
ea97eb0eb3ec: Already exists 
ec0e9aba71a6: Already exists 
2c56484238c4: Pull complete 
e04e22d751fb: Pull complete 
725acffe426c: Pull complete 
1aa9fa0253f1: Pull complete 
d7fc56cae204: Pull complete 
0697b0ac3503: Pull complete 
1b03755e0f17: Pull complete 
2c3149ca37ae: Pull complete 
27dc64abca70: Pull complete 
7ed50cc292d7: Pull complete 
Digest: sha256:943c7c57115a449353e0158dcba4eaab2e56de07b7d552b5145cb6c0d1cbab19
Status: Downloaded newer image for quay.io/prometheus/prometheus:v2.24.0
quay.io/prometheus/prometheus:v2.24.0
```

