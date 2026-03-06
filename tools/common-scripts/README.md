# Common Scripts

Miscellaneous scripts and guides used with Gloo Mesh, Istio, Envoy, and the related ecosystem for debugging and troubleshooting.

## Guides

| File | Description |
|------|-------------|
| [config_dump.md](config_dump.md) | Shell function to fetch an Envoy admin config dump (works with KGateway, Istio proxies, and Agentgateway) |
| [debug-east-west-traffic.md](debug-east-west-traffic.md) | Steps to debug east-west (multi-cluster) connectivity using `istioctl`, `netcat`, and WorkloadEntry inspection |
| [get-certificate-details.md](get-certificate-details.md) | Commands to inspect the Istio certificate chain, leaf certs, SPIFFE identities, and verify serial numbers |
| [istioctl-debug-notes.md](istioctl-debug-notes.md) | Walkthrough of debugging traffic flow with `istioctl pc` (listeners, routes, clusters, endpoints) including a full example scenario |

## Scripts

| File | Description |
|------|-------------|
| [get-snapshots.sh](get-snapshots.sh) | Retrieves input/output snapshot JSON from Gloo Mesh management server pods and saves them as zip archives |
| [get-otel-pipeline-debug-info.sh](get-otel-pipeline-debug-info.sh) | Collects metrics and logs from both telemetry collector and telemetry gateway pods, then prints key OTel pipeline counters |
| [get-gme-otel-dump-mgmt-cluster.sh](get-gme-otel-dump-mgmt-cluster.sh) | Collects metrics (ports 8888 and 9091), logs, and ConfigMaps from telemetry collector and gateway pods on a management cluster, packages everything into a tarball |
| [get-telemetry-collector-metric-dump-and-logs.sh](get-telemetry-collector-metric-dump-and-logs.sh) | Dumps metrics and logs from all telemetry collector pods in the `gloo-mesh` namespace |
| [get-telemetry-gateway-metrics-dumps-and-logs.sh](get-telemetry-gateway-metrics-dumps-and-logs.sh) | Dumps metrics and logs from all telemetry gateway pods in the `gloo-mesh` namespace |

## Subfolders

| Folder | Description |
|--------|-------------|
| [collect-gateway-resources/](collect-gateway-resources/) | Script to collect all custom resources, workloads, Helm values, and cluster info from Solo Enterprise for Agentgateway/Kgateway |
| [extract-envoy-access-log-info/](extract-envoy-access-log-info/) | Scripts to parse Envoy access log lines into a human-readable or spreadsheet-friendly format |
| [extract-files-from-yaml/](extract-files-from-yaml/) | Script to split a multi-document YAML file (e.g. from `kubectl get` or `istioctl bug-report`) into individual files organized by resource type |
