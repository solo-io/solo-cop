# Air-gap Installation Image List
This utility scripts the functionality found in the Gloo Mesh Enterprise [documentation](https://docs.solo.io/gloo-mesh-enterprise/latest/setup/install/airgap_install/).


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

where **version** is the Gloo Mesh Enterprise version.

This will print the list of images to stdout.

## Options

- `-ih | --istio-hub`         - Istio hub (Defaults to us-docker.pkg.dev/gloo-mesh/istio-workshops if not specified)
- `-iv | --istio-ver`         - Istio version (Defaults to 1.20.2 if not specified)
- `-p  | --pull`              - Execute a Docker pull
- `-sa | --skip-all`          - Skip all sub charts (By default it will pull all images)
- `-sj | --skip-jaeger`       - Skip Jaeger-related images (By default it will pull all images)
- `-sp | --skip-prom`         - Skip Prometheus-related images (By default it will pull all images)
- `-so | --skip-otel`         - Skip OpenTelemetry-related images (By default it will pull all images)
- `-r  | --retain`            - Retain '.images.out' at the end of the run and don't purge it
- `-v  | --validate`          - Validate the discovered Docker repositories
- `-d  | --debug`             - Print script debug info
- `-h  |  --help`             - Print help and exit

### Sample Output

Example output when specifying Gloo Mesh Enterprise 2.6.3 and pulling images.
```
$ ./get-image-list -p 2.6.3
Finding images for Gloo Mesh Enterprise version 2.6.3

###################################
# Getting Gloo Mesh images        #
###################################
cassandra:3.11.6
criteord/cassandra_exporter:2.0.2
docker.io/bitnami/bitnami-shell:11-debian-11-r51
docker.io/bitnami/bitnami-shell:11-debian-11-r57
docker.io/bitnami/clickhouse:23.11.1-debian-11-r1
docker.io/bitnami/jmx-exporter:0.17.2-debian-11-r23
docker.io/bitnami/kafka-exporter:1.6.0-debian-11-r34
docker.io/bitnami/kafka:3.3.1-debian-11-r19
docker.io/bitnami/kubectl:1.25.4-debian-11-r6
docker.io/bitnami/os-shell:11-debian-11-r91
docker.io/bitnami/os-shell:11-debian-11-r92
docker.io/bitnami/postgres-exporter:0.15.0-debian-11-r2
docker.io/bitnami/postgresql:16.1.0-debian-11-r15
docker.io/bitnami/zookeeper:3.8.0-debian-11-r56
docker.io/bitnami/zookeeper:3.8.3-debian-11-r3
docker.io/bitnami/zookeeper:3.9.1-debian-11-r2
gcr.io/gloo-mesh/ext-auth-service:0.55.3
gcr.io/gloo-mesh/gloo-mesh-agent:2.6.3
gcr.io/gloo-mesh/gloo-mesh-analyzer:2.6.3
gcr.io/gloo-mesh/gloo-mesh-apiserver:2.6.3
gcr.io/gloo-mesh/gloo-mesh-envoy:2.6.3
gcr.io/gloo-mesh/gloo-mesh-insights:2.6.3
gcr.io/gloo-mesh/gloo-mesh-mgmt-server:2.6.3
gcr.io/gloo-mesh/gloo-mesh-portal-server:2.6.3
gcr.io/gloo-mesh/gloo-mesh-spire-controller:2.6.3
gcr.io/gloo-mesh/gloo-mesh-ui:2.6.3
gcr.io/gloo-mesh/gloo-otel-collector:2.6.3
gcr.io/gloo-mesh/rate-limiter:0.11.7
gcr.io/gloo-mesh/kubectl:1.16.4
gcr.io/gloo-mesh/hubble-ui:v0.0.11
gcr.io/gloo-mesh/opa:0.59.0
gcr.io/gloo-mesh/prometheus:v2.49.1
gcr.io/gloo-mesh/redis:7.2.4-alpine
gcr.io/gloo-mesh/spire-server:1.8.6
gloo-mesh/gloo-network-agent-8d33bc4d8c7a/gloo-network-agent:0.2.3
gloo-mesh/sidecar-accel/sidecar-accel:0.1.1
jaegertracing/example-hotrod:latest
jimmidyson/configmap-reload:v0.8.0
maorfr/cain:0.6.0
otel/opentelemetry-collector-contrib: latest
prom/pushgateway:latest
quay.io/brancz/kube-rbac-proxy:v0.14.0
quay.io/prometheus/alertmanager:latest
quay.io/prometheus/node-exporter:latest
registry.k8s.io/kube-state-metrics/kube-state-metrics:latest

#######################################
# Getting Solo distributions of Istio #
#######################################
us-docker.pkg.dev/gloo-mesh/istio-workshops/pilot:1.22.3-patch0-solo
us-docker.pkg.dev/gloo-mesh/istio-workshops/proxyv2:1.22.3-patch0-solo

Pulling images locally
6: Pulling from library/redis
7d63c13d9b9b: Pull complete
...
```

