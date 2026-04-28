# Collect Gateway Resources

Script to collect all custom resource objects and related configuration from a Kubernetes cluster running Solo Enterprise for Agentgateway, Kgateway, or both.

## Usage

```bash
./collect-gateway-resources.sh
```

## What it collects

| Section | Description |
|---------|-------------|
| **Cluster info** | kubectl version, current context, cluster-info |
| **CRD definitions** | Full YAML of each custom resource definition associated with Gateway API, AgentGateway, and Kgateway |
| **Resource objects** | List view and full YAML for all instances of each gateway Custom Resource type |
| **Workloads** | Pods, deployments, services, configmaps, and pod logs (last 200 lines) from auto-detected agentgateway and kgateway namespaces |
| **Helm values** | User-supplied overrides, all computed values, and release metadata for agentgateway and kgateway Helm releases |

### API groups captured

- `gateway.networking.k8s.io` — Kubernetes Gateway API (Gateways, HTTPRoutes, GRPCRoutes, etc.)
- `gateway.networking.x-k8s.io` — Experimental Gateway API CRDs (XListenerSets, XBackendTrafficPolicies, XMeshes)
- `agentgateway.dev` — AgentGateway CRDs
- `enterpriseagentgateway.solo.io` — Enterprise AgentGateway CRDs
- `gateway.kgateway.dev` — Kgateway CRDs
- `enterprisekgateway.solo.io` — Enterprise Kgateway CRDs
- `ratelimit.solo.io` — Rate limiting
- `extauth.solo.io` — External auth

## Output

The script creates a timestamped directory and a `.tar.gz` archive:

```
gateway-configurations-YYYYMMDD-HHMMSS/
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

gateway-configurations-YYYYMMDD-HHMMSS.tar.gz   # shareable archive
```

## Prerequisites

- `kubectl` configured with access to the target cluster
- `helm` (optional — Helm values collection is skipped if not installed)

## Security

The script **never captures secret data**. Kubernetes Secrets are listed by name and type only.
