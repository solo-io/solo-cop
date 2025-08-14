# Usage

## Step 1 - Get the CRs in one yaml

### Get all GME CRs
```bash
kubectl get solo-io -A -o yaml > gloo-mesh-crs.yaml
```

### Get all Istio CRs
```bash
kubectl get istio-io -A -o yaml > istio-crs.yaml
```

### Get all Gloo Edge/Gateway CRs
```bash
for n in $(kubectl get crds | grep -E 'solo.io|gateway.networking.k8s.io' | awk '{print $1}'); do 
  kubectl get $n --all-namespaces -o yaml >> gloo-gateway-configuration.yaml; 
  echo "---" >> gloo-gateway-configuration.yaml; 
done
```

## Step 2 - Run the script

Pass the yaml file name as parameter to extract and organize the CRs by folder.

```bash
./extract-files-from-yaml.sh crs
```

## Sample output

Ran the script on the `crs` file that gets generated in `bug-report/cluster/` path after running `istioctl bug-report`

```bash
Extracting YAML resources from crs...
Organizing files into directories...
Processing files: 21234/21234 (100%)
Extraction complete! Files organized in: extracted-files-from-crs

Summary of extracted resources:
4907 DestinationRule
2481 ServiceEntry
2458 Sidecar
2424 EnvoyFilter
1712 VerticalPodAutoscaler
1682 PeerAuthentication
1680 AuthorizationPolicy
1461 VerticalPodAutoscalerCheckpoint
 467 APIRequestCount
 464 WorkloadEntry
 195 CertificateRequest
 195 Certificate
 190 Gateway
 135 VirtualService
  96 PodNetworkConnectivityCheck
  90 ServiceMonitor
  84 Profile
  84 Machine
  70 Telemetry
  49 PrometheusRule
  44 CredentialsRequest
  33 ClusterOperator
  29 MachineConfig
  20 ConsoleQuickStart
  17 SecurityContextConstraints
  10 MachineHealthCheck
   9 OperatorGroup
   9 MachineSet
   8 InstallPlan
   7 Subscription
   7 StorageVersionMigration
   7 OperatorCondition
   7 Operator
   7 ClusterServiceVersion
   6 MachineAutoscaler
   4 GatewayClass
   4 ConsoleCLIDownload
   4 CatalogSource
   3 OperatorPKI
   3 MachineConfigPool
   2 Upstream
   2 Prometheus
   2 Image
   2 DNS
   2 DiscoveredGateway
   2 ConsolePlugin
   2 Config
   2 ClusterCSIDriver
   1 VolumeSnapshotClass
   1 VerticalPodAutoscalerController
   1 VaultConnection
   1 VaultAuth
   1 UIPlugin
   1 Tuned
   1 ThanosRuler
   1 TempoStack
   1 Storage
   1 Settings
   1 ServiceCA
   1 Scheduler
   1 RangeAllocation
   1 Proxy
   1 Project
   1 OperatorHub
   1 OpenShiftControllerManager
   1 OpenShiftAPIServer
   1 OLMConfig
   1 OAuth
   1 Node
   1 NetworkAttachmentDefinition
   1 Network
   1 Mesh
   1 MachineConfiguration
   1 KubeStorageVersionMigrator
   1 KubeScheduler
   1 KubeletConfig
   1 KubeControllerManager
   1 KubeAPIServer
   1 KnativeServing
   1 KnativeEventing
   1 IssuedCertificate
   1 InsightsOperator
   1 IngressController
   1 Ingress
   1 Infrastructure
   1 ImagePruner
   1 HelmChartRepository
   1 GatewayParameters
   1 FeatureGate
   1 Etcd
   1 DNSRecord
   1 CSISnapshotController
   1 ControlPlaneMachineSet
   1 ControllerConfig
   1 Console
   1 ClusterVersion
   1 ClusterIssuer
   1 ClusterAutoscaler
   1 ClusterAgentConnection
   1 CloudCredential
   1 Build
   1 Authentication
   1 APIServer
   1 Alertmanager
```
