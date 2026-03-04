# Enterprise AgentGateway Config Dump

Script to collect all custom resource objects and related configuration from a Kubernetes cluster running Solo Enterprise for Agentgateway.

## Usage

```bash
# All namespaces (default)
./collect-agentgateway-resources.sh

# Specific namespace
./collect-agentgateway-resources.sh -n enterprise-agentgateway

# Custom output directory
./collect-agentgateway-resources.sh -o /tmp/my-dump
```

## What it collects

| Section | Description |
|---------|-------------|
| **Cluster info** | kubectl version, current context, cluster-info |
| **CRD definitions** | Full YAML of each custom resource definition associated with Solo Enterprise for Agentgateway |
| **Resource objects** | List view and full YAML for all instances of each gateway Custom Resource type |
| **Workloads** | Pods, deployments, services, configmaps, and pod logs (last 200 lines) from auto-detected agentgateway namespaces |
| **Helm values** | User-supplied overrides, all computed values, and release metadata for agentgateway Helm releases |

### API groups captured

- `gateway.networking.k8s.io` — Kubernetes Gateway API (Gateways, HTTPRoutes, GRPCRoutes, etc.)
- `agentgateway.dev` — AgentGateway CRDs
- `enterpriseagentgateway.solo.io` — Enterprise AgentGateway CRDs
- `ratelimit.solo.io` — Rate limiting
- `extauth.solo.io` — External auth

## Output

The script creates a timestamped directory and a `.tar.gz` archive:

```
agentgateway-dump-YYYYMMDD-HHMMSS/
├── cluster-info.txt
├── summary.txt
├── crds/
├── objects/
│   ├── <resource>.<group>.list.txt   # table view
│   └── <resource>.<group>.yaml       # full YAML
├── workloads/<namespace>/
│   ├── pods.txt
│   ├── deployments.yaml
│   ├── services.yaml
│   ├── configmaps.yaml
│   ├── secrets-list.txt              # names & types only, no secret data
│   └── logs-<pod>.txt
└── helm/
    ├── <release>.values.yaml         # user overrides
    ├── <release>.values-all.yaml     # all values (user + defaults)
    └── <release>.info.txt            # chart version, status, revision

agentgateway-dump-YYYYMMDD-HHMMSS.tar.gz   # shareable archive
```

## Prerequisites

- `kubectl` configured with access to the target cluster
- `helm` (optional — Helm values collection is skipped if not installed)
