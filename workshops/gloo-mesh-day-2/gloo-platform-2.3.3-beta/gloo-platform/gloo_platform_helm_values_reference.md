
---
title: "Gloo Platform"
description: Reference for Helm values.
weight: 2
---

|Option|Type|Default Value|Description|
|------|----|-----------|-------------|
|experimental|struct| |Experimental features for Gloo Platform. Disabled by default. Do not use in production.|
|experimental.ambientEnabled|bool|false|Allow Gloo Mesh to create Istio Ambient Mesh resources.|
|experimental.asyncStatusWrites|bool|false|Enable asynchronous writing of statuses to Kubernetes objects.|
|prometheus|map| |Helm values for configuring Prometheus. See the [Prometheus Helm chart](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml) for the complete set of values.|
|legacyMetricsPipeline|struct| |Configuration for the legacy metrics pipeline, which uses Gloo agents to propagate metrics to the management server.|
|legacyMetricsPipeline.enabled|bool|false|Set to false to disable the legacy telemetry pipeline.|
|glooNetwork|struct| |Gloo Network configuration options.|
|glooNetwork.enabled|bool|false|Enable translation of network policies to enforce access policies and service isolation.|
|redis|struct| |Redis configuration options.|
|redis.address|string|gloo-mesh-redis.gloo-mesh:6379|Address to use when connecting to the Redis instance. To use the default Redis deployment, specify 'redis.gloo-mesh.svc.cluster.local:6379'.|
|redis.auth|struct| |Optional authentication values to use when connecting to the Redis instance|
|redis.auth.enabled|bool|false|Connect to the Redis instance with a password|
|redis.auth.secretName|string|redis-auth-secrets|Name of the k8s secret that contains the password|
|redis.auth.usernameKey|string|username|The secret key containing the username to use for authentication|
|redis.auth.passwordKey|string|password|The secret key containing the password to use for authentication|
|redis.db|int|0|DB to connect to|
|redis.certs|struct| |Configuration for TLS verification when connecting to the Redis instance|
|redis.certs.enabled|bool|false|Enable a secure network connection to the Redis instance via TLS|
|redis.certs.caCertKey|string| |The secret key containing the ca cert|
|redis.certs.secretName|string|redis-certs|Name of the k8s secret that contains the certs|
|redis.connection|struct| |Optional connection parameters|
|redis.connection.maxRetries|int|3|Maximum number of retries before giving up. Default is 3. -1 disables retries.|
|redis.connection.minRetryBackoff|string|8ms|Minimum backoff between each retry. Default is 8 milliseconds. -1 disables backoff.|
|redis.connection.maxRetryBackoff|string|512ms|Maximum backoff between each retry. Default is 512 milliseconds. -1 disables backoff.|
|redis.connection.dialTimeout|string|5s|Dial timeout for establishing new connections. Default is 5 seconds.|
|redis.connection.readTimeout|string|3s|Timeout for socket reads. if reached, commands will fail with a timeout instead of blocking. Default is 3 seconds. -1 disables timeout. 0 uses the default value.|
|redis.connection.writeTimeout|string| |Timeout for socket writes. If reached, commands will fail with a timeout instead of blocking. Default is ReadTimeout.|
|redis.connection.poolFifo|bool|false|Type of connection pool. true for FIFO pool. false for LIFO pool. Note that FIFO has higher overhead compared to LIFO.|
|redis.connection.poolSize|int|0|Maximum number of socket connections. Default is 10 connections per every available CPU as reported by runtime.GOMAXPROCS.|
|redis.connection.minIdleConns|int|0|Minimum number of idle connections which is useful when establishing new connection is slow.|
|redis.connection.maxConnAge|string| |Connection age at which client retires (closes) the connection. Default is to not close aged connections.|
|redis.connection.poolTimeout|string| |Amount of time client waits for connection if all connections are busy before returning an error. Default is ReadTimeout + 1 second.|
|redis.connection.idleTimeout|string|5m0s|Amount of time after which client closes idle connections. Should be less than server's timeout. Default is 5 minutes. -1 disables idle timeout check.|
|redis.connection.idleCheckFrequency|string|1m0s|Frequency of idle checks made by idle connections reaper. Default is 1 minute. -1 disables idle connections reaper, but idle connections are still discarded by the client if IdleTimeout is set.|
|common|struct| |Common values shared across components. When applicable, these can be overridden in specific components.|
|common|struct| ||
|common.leaderElection|bool|true|Enable leader election for the high-availability deployment.|
|common|struct| ||
|common.verbose|bool|false|Enable verbose/debug logging.|
|common|struct| ||
|common.devMode|bool|false|Set to true to enable development mode for the logger, which can cause panics. Do not use in production.|
|common|struct| ||
|common.insecure|bool|false|Permit unencrypted and unauthenticated communication between Gloo control and data planes. Do not use in production.|
|common|struct| ||
|common.prometheusUrl|string|http://prometheus-server|Prometheus server address.|
|common|struct| ||
|common.adminNamespace|string| |Namespace to install control plane components into. The admin namespace also contains global configuration, such as Workspace, global overrides WorkspaceSettings, and KubernetesCluster resources.|
|common|struct| ||
|common.readOnlyGeneratedResources|bool|false|If true, the deployment only reads Istio resource outputs that are created by Gloo Platform, and filters out Istio resource fields that Gloo Mesh cannot properly unmarshal. These other resource outputs are not visible in the Gloo UI.|
|common.addonNamespace|string|gloo-mesh-addons|Namespace to install add-on components into, such as the Gloo external auth and rate limiting services.|
|common.cluster|string| |Name of the cluster. Be sure to modify this value to match your cluster's name.|
|common.clusterDomain|string| |The local cluster domain suffix this cluster is configured with. Defaults to 'cluster.local'.|
|demo|struct| |Demo-specific features that improve quick setups. Do not use in production.|
|demo.manageAddonNamespace|bool|false|Automatically create the add-on namespace set in 'common.addonNamespace'.|
|licensing|struct| |Gloo Platform product licenses.|
|licensing.licenseKey|string| |Deprecated: Legacy Gloo Mesh Enterprise license key. Use individual product license fields, the trial license field, or a license secret instead.|
|licensing.glooGatewayLicenseKey|string| |Gloo Gateway license key.|
|licensing.glooMeshLicenseKey|string| |Gloo Mesh Enterprise license key.|
|licensing.glooNetworkLicenseKey|string| |Gloo Network license key.|
|licensing.glooTrialLicenseKey|string| |Gloo trial license key, for a trial installation of all products.|
|licensing.licenseSecretName|string| |Provide license keys in a secret in the adminNamespace of the management cluster, instead of in the license key fields.|
|glooAgent|struct| |Configuration for the Gloo agent.|
|glooAgent|struct| ||
|glooAgent|struct| ||
|glooAgent.leaderElection|bool|false|Enable leader election for the high-availability deployment.|
|glooAgent|struct| ||
|glooAgent.verbose|bool|false|Enable verbose/debug logging.|
|glooAgent|struct| ||
|glooAgent.devMode|bool|false|Set to true to enable development mode for the logger, which can cause panics. Do not use in production.|
|glooAgent|struct| ||
|glooAgent.insecure|bool|false|Permit unencrypted and unauthenticated communication between Gloo control and data planes. Do not use in production.|
|glooAgent|struct| ||
|glooAgent.readOnlyGeneratedResources|bool|false|If true, the deployment only reads Istio resource outputs that are created by Gloo Platform, and filters out Istio resource fields that Gloo Mesh cannot properly unmarshal. These other resource outputs are not visible in the Gloo UI.|
|glooAgent.relay|struct| |Configuration for securing relay communication between the workload agents and the management server.|
|glooAgent.relay.serverAddress|string| |Address and port by which gloo-mesh-mgmt-server in the Gloo control plane can be accessed by the Gloo workload agents.|
|glooAgent.relay.authority|string|gloo-mesh-mgmt-server.gloo-mesh|SNI name in the authority/host header used to connect to relay forwarding server. Must match server certificate CommonName. Do not change the default value.|
|glooAgent.relay.clientTlsSecret|struct| |Custom certs: Secret containing client TLS certs used to identify the Gloo agent to the management server. If you do not specify a clientTlssSecret, you must specify a tokenSecret and a rootTlsSecret.|
|glooAgent.relay.clientTlsSecret.name|string|relay-client-tls-secret||
|glooAgent.relay.clientTlsSecret.namespace|string| ||
|glooAgent.relay.rootTlsSecret|struct| |Secret containing a root TLS cert used to verify the management server cert. The secret can also optionally specify a 'tls.key', which is used to generate the agent client cert.|
|glooAgent.relay.rootTlsSecret.name|string|relay-root-tls-secret||
|glooAgent.relay.rootTlsSecret.namespace|string| ||
|glooAgent.relay.tokenSecret|struct| |Secret containing a shared token for authenticating Gloo agents when they first communicate with the management server. A token secret is not needed with ACM certs.|
|glooAgent.relay.tokenSecret.name|string|relay-identity-token-secret|Name of the Kubernetes secret.|
|glooAgent.relay.tokenSecret.namespace|string| |Namespace of the Kubernetes secret.|
|glooAgent.relay.tokenSecret.key|string|token|Key value of the data within the Kubernetes secret.|
|glooAgent.relay.clientTlsSecretRotationGracePeriodRatio|string| |The ratio of the client TLS certificate lifetime to when the management server starts the certificate rotation process.|
|glooAgent.maxGrpcMessageSize|string|4294967295|Maximum message size for gRPC messages sent and received by the management server.|
|glooAgent.metricsBufferSize|int|50|Number of metrics messages to buffer per Envoy proxy.|
|glooAgent.accessLogsBufferSize|int|50|Number of access logs to buffer per Envoy proxy.|
|glooAgent.istiodSidecar|struct| |Configuration for the istiod sidecar deployment.|
|glooAgent.istiodSidecar.createRoleBinding|bool|false|Create the cluster role binding for the istiod sidecar.|
|glooAgent.istiodSidecar.istiodServiceAccount|struct| |Object reference for the istiod service account.|
|glooAgent.istiodSidecar.istiodServiceAccount.name|string|istiod||
|glooAgent.istiodSidecar.istiodServiceAccount.namespace|string|istio-system||
|glooAgent.enabled|bool|false|Configuration for the Gloo agent.|
|glooMgmtServer|struct| |Configuration for the Gloo management server.|
|glooMgmtServer.registerCluster|bool|false|Register the management cluster by deploying a Gloo agent to the cluster alongside the management server, such as for single-cluster Gloo Gateway, quickstart, or testing setups. This setting is not recommended for multicluster or production setups.|
|extAuthService|struct| |Configuration for the Gloo external authentication service.|
|extAuthService.enabled|bool|false|Enable the Gloo external authentication service.|
|extAuthService.extAuth|struct| |Configuration for the extauth service.|
|extAuthService.extAuth.logLevel|string|INFO|Severity level to collect logs for.|
|extAuthService.extAuth.watchNamespace|string| |Namespaces to watch in your cluster. If omitted or empty, all namespaces are watched.|
|extAuthService.extAuth.image|struct| |Values for the extauth image.|
|extAuthService.extAuth.image.repository|string|ext-auth-service|Image name (repository).|
|extAuthService.extAuth.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|extAuthService.extAuth.image.tag|string|0.35.2|Version tag for the container.|
|extAuthService.extAuth.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|extAuthService.extAuth.resources|struct| |Values for the container resource requests.|
|extAuthService.extAuth.resources.requests|struct| |Minimum amount of compute resources required. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).|
|extAuthService.extAuth.resources.requests.cpu|string|125m|Amount of CPU resource.|
|extAuthService.extAuth.resources.requests.memory|string|256Mi|Amount of memory resource.|
|extAuthService.extAuth.userIdHeader|string| |User ID header.|
|extAuthService.extAuth.signingKey|string| |Provide the server's secret signing key. If empty, a random key is generated.|
|extAuthService.extAuth.signingKeyFile|struct| |Mount the secret as a file rather than pass the signing key as a environment variable. To ensure maximum security by default, the file is limited to 0440 permissions and the fsGroup matches the runAsGroup.|
|extAuthService.extAuth.signingKeyFile.enabled|bool|false|Mount the secret as a file.|
|extAuthService.extAuth.signingKeyFile.fileMode|int|288|File permission.|
|extAuthService.extAuth.signingKeyFile.groupSettingEnabled|bool|true|Set to true to use a volume group.|
|extAuthService.extAuth.signingKeyFile.fsGroup|int|10101|Group ID for volume ownership.|
|extAuthService.extAuth.signingKeyFile.runAsUser|int|10101|User ID for the container to run as.|
|extAuthService.extAuth.signingKeyFile.runAsGroup|int|10101|Group ID for the container to run as.|
|extAuthService.extAuth.pluginDirectory|string|/auth-plugins/|Directory in which the server expects Go plugin .so files.|
|extAuthService.extAuth.headersToRedact[]|[]string|["authorization"]|Headers that will be redacted in the server logs.|
|extAuthService.extAuth.headersToRedact[]|string| |Headers that will be redacted in the server logs.|
|extAuthService.extAuth.healthCheckFailTimeout|int|15|When receiving a termination signal, the pod waits this amount of seconds for a request that it can use to notify Envoy that it should fail the health check for this endpoint. If no request is received within this interval, the server will shutdown gracefully. The interval should be greater than the active health check interval configured in Envoy for this service.|
|extAuthService.extAuth.healthCheckHttpPath|string|/healthcheck|Path for Envoy health checks.|
|extAuthService.extAuth.healthLivenessCheckHttpPath|string|/livenesscheck|Path for liveness health checks.|
|extAuthService.extAuth.service|struct| |Configuration for the deployed extauth service.|
|extAuthService.extAuth.service.type|string|ClusterIP|Kubernetes servie type.|
|extAuthService.extAuth.service.grpcPort|int|8083|Port the extauth server listens on for gRPC requests.|
|extAuthService.extAuth.service.debugPort|int|9091|Port on the extauth server to pull logs from.|
|extAuthService.extAuth.service.healthPort|int|8082|Port the extauth server listens on for health checks.|
|extAuthService.extAuth.service.grpcNodePort|int|32000|Only relevant if the service is of type NodePort.|
|extAuthService.extAuth.service.debugNodePort|int|32001|Only relevant if the service is of type NodePort.|
|extAuthService.extAuth.service.healthNodePort|int|32002|Only relevant if the service is of type NodePort.|
|extAuthService.extraLabels|map[string, string]|null|Extra key-value pairs to add to the labels data of the extauth deployment.|
|extAuthService.extraLabels.<MAP_KEY>|string| |Extra key-value pairs to add to the labels data of the extauth deployment.|
|extAuthService.extraTemplateAnnotations|map[string, string]|{"proxy.istio.io/config":"{ \"holdApplicationUntilProxyStarts\": true }"}|Extra annotations to add to the extauth service pods.|
|extAuthService.extraTemplateAnnotations.<MAP_KEY>|string| |Extra annotations to add to the extauth service pods.|
|extAuthService.extraTemplateAnnotations.proxy.istio.io/config|string|{ "holdApplicationUntilProxyStarts": true }|Extra annotations to add to the extauth service pods.|
|rateLimiter|struct| |Configuration for the Gloo rate limiting service.|
|rateLimiter.enabled|bool|false|Enable the Gloo rate limiting service.|
|rateLimiter.rateLimiter|struct| |Configuration for the rate limiter.|
|rateLimiter.rateLimiter.logLevel|string|INFO|Severity level to collect logs for.|
|rateLimiter.rateLimiter.watchNamespace|string| |Namespaces to watch in your cluster. If omitted or empty, all namespaces are watched.|
|rateLimiter.rateLimiter.image|struct| |Values for the rate limiter image.|
|rateLimiter.rateLimiter.image.repository|string|rate-limiter|Image name (repository).|
|rateLimiter.rateLimiter.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|rateLimiter.rateLimiter.image.tag|string|0.8.0|Version tag for the container.|
|rateLimiter.rateLimiter.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|rateLimiter.rateLimiter.resources|struct| |Values for the container resource requests.|
|rateLimiter.rateLimiter.resources.requests|struct| |Minimum amount of compute resources required. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).|
|rateLimiter.rateLimiter.resources.requests.cpu|string|125m|Amount of CPU resource.|
|rateLimiter.rateLimiter.resources.requests.memory|string|256Mi|Amount of memory resource.|
|rateLimiter.rateLimiter.ports|struct| |Ports for the rate limiter service.|
|rateLimiter.rateLimiter.ports.grpc|uint32|8083|Port the rate limiter listens on for gRPC requests.|
|rateLimiter.rateLimiter.ports.ready|uint32|8084|Port the rate limiter listens on for readiness checks.|
|rateLimiter.rateLimiter.ports.debug|uint32|9091|Port on the rate limiter to pull logs from.|
|rateLimiter.rateLimiter.readyPath|string|/ready|Path for readiness checks.|
|rateLimiter.rateLimiter.installClusterRoles|bool|true|If true, use ClusterRoles. If false, use Roles.|
|rateLimiter.redis|struct| |Configuration for using a Redis instance for authentication.|
|rateLimiter.redis.image|struct| |Values for the Redis image.|
|rateLimiter.redis.image.repository|string|redis|Image name (repository).|
|rateLimiter.redis.image.registry|string|docker.io|Image registry.|
|rateLimiter.redis.image.tag|string|6.2.6|Version tag for the container.|
|rateLimiter.redis.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|rateLimiter.redis.service|struct| |Values for the Redis service.|
|rateLimiter.redis.service.port|int|6379|Port for the Redis service.|
|rateLimiter.redis.service.name|string|redis|Name for the Redis service.|
|rateLimiter.redis.service.socket|string|tcp|'unix', 'tcp', or 'tls' are supported.|
|rateLimiter.redis.hostname|string|redis|Hostname clients use to connect to the Redis instance.|
|rateLimiter.redis.clustered|bool|false|Set to true if your Redis instance runs in clustered mode.|
|rateLimiter.redis.auth|struct| |Values for the authentication details.|
|rateLimiter.redis.auth.enabled|bool|false|Use the default Redis instance for authentication.|
|rateLimiter.redis.auth.secretName|string|redis-secrets|Name of the secret that contains the username and password.|
|rateLimiter.redis.auth.passwordKey|string|redis-password|Key that contains the password.|
|rateLimiter.redis.auth.usernameKey|string|redis-username|Key that contains the username. If Redis doesn't have an explicit username, specify 'default'.|
|rateLimiter.redis.enabled|bool|true|Install the default Redis instance.|
|rateLimiter.redis.certs|struct| |Provide a CA cert for the rate limiter and Redis instance (if enabled) to use.|
|rateLimiter.redis.certs.enabled|bool|false|Enable the rate limiter and Redis instance (if enabled) to use the CA cert you provide.|
|rateLimiter.redis.certs.mountPoint|string|/etc/tls|Mount path for the certs.|
|rateLimiter.redis.certs.caCert|string|redis.crt|File name that contains the CA cert.|
|rateLimiter.redis.certs.signingKey|string|redis.key|File name that contains the signing key. Only relevant for the Redis instance.|
|rateLimiter.redis.certs.secretName|string|redis-certs-keys|Name of the secret for the CA cert.|
|rateLimiter.extraLabels|map[string, string]|null|Extra key-value pairs to add to the labels data of the rate limiter deployment.|
|rateLimiter.extraLabels.<MAP_KEY>|string| |Extra key-value pairs to add to the labels data of the rate limiter deployment.|
|rateLimiter.extraTemplateAnnotations|map[string, string]|{"proxy.istio.io/config":"{ \"holdApplicationUntilProxyStarts\": true }"}|Extra annotations to add to the rate limiter service pods.|
|rateLimiter.extraTemplateAnnotations.<MAP_KEY>|string| |Extra annotations to add to the rate limiter service pods.|
|rateLimiter.extraTemplateAnnotations.proxy.istio.io/config|string|{ "holdApplicationUntilProxyStarts": true }|Extra annotations to add to the rate limiter service pods.|
|sidecarAccel|struct| |Experimental: Configuration for eBPF sidecar acceleration. Do not use in production.|
|sidecarAccel.enabled|bool|false|Enable eBPF sidecar acceleration to reduce network latency in your service mesh.|
|sidecarAccel.fullname|string|sidecar-accel|Name of the sidecar acceleration deployment.|
|sidecarAccel.namespace|string|istio-system|Namespace to deploy sidecar acceleration into.|
|sidecarAccel.ipsFilePath|string| ||
|sidecarAccel.debug|bool|false|Run sidecar acceleration in debug mode.|
|sidecarAccel.image|struct| |Values for the sidecar acceleration image.|
|sidecarAccel.image.hub|string|us-docker.pkg.dev|Image registry.|
|sidecarAccel.image.repository|string|gloo-mesh/sidecar-accel/sidecar-accel|Image name (repository).|
|sidecarAccel.image.tag|string|0.1.0|Version tag for the container.|
|sidecarAccel.image.pullPolicy|string|Always|Image pull policy.|
|sidecarAccel.resources|struct| |Values for the container and init container.|
|sidecarAccel.resources.container|struct| |Resource values for the container.|
|sidecarAccel.resources.container.limit|struct| |Maximum amount of compute resources allowed. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).|
|sidecarAccel.resources.container.limit.cpu|string|300m|Amount of CPU resource.|
|sidecarAccel.resources.container.limit.memory|string|200Mi|Amount of memory resource.|
|sidecarAccel.resources.container.request|struct| |Minimum amount of compute resources required. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).|
|sidecarAccel.resources.container.request.cpu|string|100m|Amount of CPU resource.|
|sidecarAccel.resources.container.request.memory|string|200Mi|Amount of memory resource.|
|sidecarAccel.resources.init|struct| |Resource values for the init container.|
|sidecarAccel.resources.init.limit|struct| |Maximum amount of compute resources allowed. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).|
|sidecarAccel.resources.init.limit.cpu|string|300m|Amount of CPU resource.|
|sidecarAccel.resources.init.limit.memory|string|50Mi|Amount of memory resource.|
|sidecarAccel.resources.init.request|struct| |Minimum amount of compute resources required. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).|
|sidecarAccel.resources.init.request.cpu|string|100m|Amount of CPU resource.|
|sidecarAccel.resources.init.request.memory|string|50Mi|Amount of memory resource.|
|sidecarAccel.dnsPolicy|string| ||
|sidecarAccel.revisionHistoryLimit|int|10|Number of old ReplicaSets for the agent deployment you want to retain.|
|istioInstallations|struct| |Configuration for deploying managed Istio control plane and gateway installations by using the Istio lifecycle manager.|
|istioInstallations.controlPlane|struct| |Configuration for the managed Istio control plane instance.|
|istioInstallations.controlPlane.enabled|bool|true|Install the managed Istio control plane instance in the cluster.|
|istioInstallations.controlPlane.installations[]|[]struct|[{"revision":"auto","clusters":null,"istioOperatorSpec":{}}]|List of Istio control plane installations.|
|istioInstallations.controlPlane.installations[]|struct| |List of Istio control plane installations.|
|istioInstallations.controlPlane.installations[].revision|string| |Istio revision for this installation, such as '1-17'. Label workload resources with 'istio.io/rev=$REVISION' to use this installation. Defaults to 'AUTO', which installs the default supported version of Gloo Istio.|
|istioInstallations.controlPlane.installations[].clusters[]|[]ptr| |Clusters to install the Istio control planes in.|
|istioInstallations.controlPlane.installations[].clusters[]|struct| |Clusters to install the Istio control planes in.|
|istioInstallations.controlPlane.installations[].clusters[].name|string| |Name of the cluster to install Istio into. Must match the registered cluster name.|
|istioInstallations.controlPlane.installations[].clusters[].defaultRevision|bool| |When set to true, the installation for this revision is applied as the active Istio installation in the cluster. Resources with the 'istio-injection=true' label entry use this revision. You might change this setting for Istio installations during a canary upgrade. For more info, see the [upgrade docs](https://docs.solo.io/gloo-gateway/main/setup/upgrade/#upgrade-ilcm).|
|istioInstallations.controlPlane.installations[].clusters[].trustDomain|string| |Trust domain value for this cluster's Istio installation mesh config. Defaults to the cluster's name.|
|istioInstallations.controlPlane.installations[].istioOperatorSpec|struct| |IstioOperator specification for the control plane. For more info, see the [IstioOperatorSpec reference](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/api/istio_operator/#istiooperatorspec).|
|istioInstallations.northSouthGateways[]|[]struct|[{"name":"istio-ingressgateway","enabled":true,"installations":[{"gatewayRevision":"auto","clusters":null,"istioOperatorSpec":{}}]}]|Configuration for the managed north-south (ingress) gateway. Requires a Gloo Gateway license.|
|istioInstallations.northSouthGateways[]|struct| |Configuration for the managed north-south (ingress) gateway. Requires a Gloo Gateway license.|
|istioInstallations.northSouthGateways[].name|string| |Name of the gateway. Must be unique.|
|istioInstallations.northSouthGateways[].enabled|bool| |Install the gateway in the cluster.|
|istioInstallations.northSouthGateways[].installations[]|[]struct| |List of Istio gateway installations. For more info, see the [GatewayInstallation reference](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/api/gateway_lifecycle_manager/#gatewayinstallation).|
|istioInstallations.northSouthGateways[].installations[]|struct| |List of Istio gateway installations. For more info, see the [GatewayInstallation reference](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/api/gateway_lifecycle_manager/#gatewayinstallation).|
|istioInstallations.northSouthGateways[].installations[].controlPlaneRevision|string| |Optional: The revision of an Istio control plane in the cluster that this gateway should also use. If a control plane installation of this revision is not found, no gateway is created.|
|istioInstallations.northSouthGateways[].installations[].gatewayRevision|string| |Istio revision for this installation, such as '1-17'. Defaults to 'AUTO', which installs the default supported version of Gloo Istio.|
|istioInstallations.northSouthGateways[].installations[].clusters[]|[]ptr| |Clusters to install the gateway in.|
|istioInstallations.northSouthGateways[].installations[].clusters[]|struct| |Clusters to install the gateway in.|
|istioInstallations.northSouthGateways[].installations[].clusters[].name|string| |Name of the cluster to install the gateway into. Must match the registered cluster name.|
|istioInstallations.northSouthGateways[].installations[].clusters[].activeGateway|bool| |When set to true, the installation for this revision is applied as the active gateway through which primary service traffic is routed in the cluster. If the istioOperatorSpec defines a service, this field switches the service selectors to the revision specified in the gatewayRevsion. You might change this setting for gateway installations during a canary upgrade. For more info, see the [upgrade docs](https://docs.solo.io/gloo-gateway/main/setup/upgrade/#upgrade-ilcm).|
|istioInstallations.northSouthGateways[].installations[].clusters[].trustDomain|string| |Trust domain value for this cluster's Istio installation mesh config. Defaults to the cluster's name.|
|istioInstallations.northSouthGateways[].installations[].istioOperatorSpec|struct| |IstioOperator specification for the gateway. For more info, see the [IstioOperatorSpec reference](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/api/istio_operator/#istiooperatorspec).|
|istioInstallations.eastWestGateways[]|[]struct|null|Configuration for the managed east-west gateway.|
|istioInstallations.eastWestGateways[]|struct| |Configuration for the managed east-west gateway.|
|istioInstallations.eastWestGateways[].name|string| |Name of the gateway. Must be unique.|
|istioInstallations.eastWestGateways[].enabled|bool| |Install the gateway in the cluster.|
|istioInstallations.eastWestGateways[].installations[]|[]struct| |List of Istio gateway installations. For more info, see the [GatewayInstallation reference](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/api/gateway_lifecycle_manager/#gatewayinstallation).|
|istioInstallations.eastWestGateways[].installations[]|struct| |List of Istio gateway installations. For more info, see the [GatewayInstallation reference](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/api/gateway_lifecycle_manager/#gatewayinstallation).|
|istioInstallations.eastWestGateways[].installations[].controlPlaneRevision|string| |Optional: The revision of an Istio control plane in the cluster that this gateway should also use. If a control plane installation of this revision is not found, no gateway is created.|
|istioInstallations.eastWestGateways[].installations[].gatewayRevision|string| |Istio revision for this installation, such as '1-17'. Defaults to 'AUTO', which installs the default supported version of Gloo Istio.|
|istioInstallations.eastWestGateways[].installations[].clusters[]|[]ptr| |Clusters to install the gateway in.|
|istioInstallations.eastWestGateways[].installations[].clusters[]|struct| |Clusters to install the gateway in.|
|istioInstallations.eastWestGateways[].installations[].clusters[].name|string| |Name of the cluster to install the gateway into. Must match the registered cluster name.|
|istioInstallations.eastWestGateways[].installations[].clusters[].activeGateway|bool| |When set to true, the installation for this revision is applied as the active gateway through which primary service traffic is routed in the cluster. If the istioOperatorSpec defines a service, this field switches the service selectors to the revision specified in the gatewayRevsion. You might change this setting for gateway installations during a canary upgrade. For more info, see the [upgrade docs](https://docs.solo.io/gloo-gateway/main/setup/upgrade/#upgrade-ilcm).|
|istioInstallations.eastWestGateways[].installations[].clusters[].trustDomain|string| |Trust domain value for this cluster's Istio installation mesh config. Defaults to the cluster's name.|
|istioInstallations.eastWestGateways[].installations[].istioOperatorSpec|struct| |IstioOperator specification for the gateway. For more info, see the [IstioOperatorSpec reference](https://docs.solo.io/gloo-mesh-enterprise/latest/reference/api/istio_operator/#istiooperatorspec).|
|istioInstallations.enabled|bool|false|Enable managed Istio installations.|
|telemetryGateway|struct| |Configuration for the Gloo Platform Telemetry Gateway. See the [OpenTelemetry Helm chart](https://github.com/open-telemetry/opentelemetry-helm-charts/blob/main/charts/opentelemetry-collector/values.yaml) for the complete set of values.|
|telemetryGatewayCustomization|struct| |Optional customization for the Gloo Platform Telemetry Gateway.|
|telemetryGatewayCustomization.serverName|string|gloo-telemetry-gateway.gloo-mesh|SNI and certificate subject alternative name used in the telemetry gateway certificate.|
|telemetryGatewayCustomization.extraReceivers|map[string, interface]|null|Configuration for extra receivers, such as to scrape extra Prometheus targets. Receivers listen on a network port to receive telemetry data.|
|telemetryGatewayCustomization.extraReceivers.<MAP_KEY>|interface| |Configuration for extra receivers, such as to scrape extra Prometheus targets. Receivers listen on a network port to receive telemetry data.|
|telemetryGatewayCustomization.extraProcessors|map[string, interface]|{"batch":{"send_batch_max_size":3000,"send_batch_size":2000,"timeout":"600ms"},"memory_limiter":{"check_interval":"1s","limit_percentage":85,"spike_limit_percentage":10}}|Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryGatewayCustomization.extraProcessors.<MAP_KEY>|interface| |Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryGatewayCustomization.extraProcessors.batch|interface| |Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryGatewayCustomization.extraProcessors.memory_limiter|interface| |Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryGatewayCustomization.extraExporters|map[string, interface]|null|Configuration for extra exporters, such as to forward your data to a third-party provider. Exporters forward the data they get to a destination on the local or remote network.|
|telemetryGatewayCustomization.extraExporters.<MAP_KEY>|interface| |Configuration for extra exporters, such as to forward your data to a third-party provider. Exporters forward the data they get to a destination on the local or remote network.|
|telemetryGatewayCustomization.extraPipelines|map[string, interface]|null|Specify any added receivers, processors, or exporters in an extra pipeline.|
|telemetryGatewayCustomization.extraPipelines.<MAP_KEY>|interface| |Specify any added receivers, processors, or exporters in an extra pipeline.|
|telemetryGatewayCustomization.telemetry|map[string, interface]|{"metrics":{"address":"0.0.0.0:8888"}}|Configure the service telemetry (logs and metrics) as described in the [otel-collector docs](https://opentelemetry.io/docs/collector/configuration/#service).|
|telemetryGatewayCustomization.telemetry.<MAP_KEY>|interface| |Configure the service telemetry (logs and metrics) as described in the [otel-collector docs](https://opentelemetry.io/docs/collector/configuration/#service).|
|telemetryGatewayCustomization.telemetry.metrics|interface| |Configure the service telemetry (logs and metrics) as described in the [otel-collector docs](https://opentelemetry.io/docs/collector/configuration/#service).|
|telemetryGatewayCustomization.reloadTlsCertificate|struct| |Interval of time between reloading the TLS certificate of the telemetry gateway.|
|telemetryGatewayCustomization.reloadTlsCertificate.seconds|int64|0||
|telemetryGatewayCustomization.reloadTlsCertificate.nanos|int32|0||
|telemetryGatewayCustomization.disableCertGeneration|bool|false|Disable cert generation for the Gloo Platform Telemetry Gateway.|
|telemetryGatewayCustomization.disableDefaultPipeline|bool|false|Disables the default pipeline. Useful if you want to create a custom pipeline using 'extraPipelines' and to disable the default pipeline.|
|telemetryCollector|struct| |Configuration for the Gloo Platform Telemetry Collector. See the [OpenTelemetry Helm chart](https://github.com/open-telemetry/opentelemetry-helm-charts/blob/main/charts/opentelemetry-collector/values.yaml) for the complete set of values.|
|telemetryCollectorCustomization|struct| |Optional customization for the Gloo Platform Telemetry Collector.|
|telemetryCollectorCustomization.serverName|string|gloo-telemetry-gateway.gloo-mesh|SNI and certificate subject alternative name used in the collector certificate.|
|telemetryCollectorCustomization.extraReceivers|map[string, interface]|null|Configuration for extra receivers, such as to scrape extra Prometheus targets. Receivers listen on a network port to receive telemetry data.|
|telemetryCollectorCustomization.extraReceivers.<MAP_KEY>|interface| |Configuration for extra receivers, such as to scrape extra Prometheus targets. Receivers listen on a network port to receive telemetry data.|
|telemetryCollectorCustomization.extraProcessors|map[string, interface]|{"batch":{"send_batch_max_size":3000,"send_batch_size":2000,"timeout":"600ms"},"memory_limiter":{"check_interval":"1s","limit_percentage":85,"spike_limit_percentage":10}}|Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryCollectorCustomization.extraProcessors.<MAP_KEY>|interface| |Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryCollectorCustomization.extraProcessors.batch|interface| |Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryCollectorCustomization.extraProcessors.memory_limiter|interface| |Configuration for extra processors to drop and generate new data. Processors can transform the data before it is forwarded to another processor and an exporter.|
|telemetryCollectorCustomization.extraExporters|map[string, interface]|null|Configuration for extra exporters, such as to forward your data to a third-party provider. Exporters forward the data they get to a destination on the local or remote network.|
|telemetryCollectorCustomization.extraExporters.<MAP_KEY>|interface| |Configuration for extra exporters, such as to forward your data to a third-party provider. Exporters forward the data they get to a destination on the local or remote network.|
|telemetryCollectorCustomization.extraPipelines|map[string, interface]|null|Specify any added receivers, processors, or exporters in an extra pipeline.|
|telemetryCollectorCustomization.extraPipelines.<MAP_KEY>|interface| |Specify any added receivers, processors, or exporters in an extra pipeline.|
|telemetryCollectorCustomization.telemetry|map[string, interface]|{"metrics":{"address":"0.0.0.0:8888"}}|Configure the service telemetry (logs and metrics) as described in the [otel-collector docs](https://opentelemetry.io/docs/collector/configuration/#service).|
|telemetryCollectorCustomization.telemetry.<MAP_KEY>|interface| |Configure the service telemetry (logs and metrics) as described in the [otel-collector docs](https://opentelemetry.io/docs/collector/configuration/#service).|
|telemetryCollectorCustomization.telemetry.metrics|interface| |Configure the service telemetry (logs and metrics) as described in the [otel-collector docs](https://opentelemetry.io/docs/collector/configuration/#service).|
|telemetryCollectorCustomization.disableDefaultPipeline|bool|false|Disables the default pipeline. Useful if you want to create a custom pipeline using 'extraPipelines' and to disable the default pipeline.|
|glooMgmtServer|struct| |Configuration for the glooMgmtServer deployment.|
|glooMgmtServer|struct| ||
|glooMgmtServer.leaderElection|bool|false|Enable leader election for the high-availability deployment.|
|glooMgmtServer|struct| ||
|glooMgmtServer.verbose|bool|false|Enable verbose/debug logging.|
|glooMgmtServer|struct| ||
|glooMgmtServer.devMode|bool|false|Set to true to enable development mode for the logger, which can cause panics. Do not use in production.|
|glooMgmtServer|struct| ||
|glooMgmtServer.insecure|bool|false|Permit unencrypted and unauthenticated communication between Gloo control and data planes. Do not use in production.|
|glooMgmtServer|struct| ||
|glooMgmtServer.readOnlyGeneratedResources|bool|false|If true, the deployment only reads Istio resource outputs that are created by Gloo Platform, and filters out Istio resource fields that Gloo Mesh cannot properly unmarshal. These other resource outputs are not visible in the Gloo UI.|
|glooMgmtServer.relay|struct| |Configuration for certificates to secure server-agent relay communication. Required only for multicluster setups.|
|glooMgmtServer.relay.tlsSecret|struct| |Secret containing client TLS certs used to secure the management server.|
|glooMgmtServer.relay.tlsSecret.name|string|relay-server-tls-secret||
|glooMgmtServer.relay.tlsSecret.namespace|string| ||
|glooMgmtServer.relay.signingTlsSecret|struct| |Secret containing TLS certs used to sign CSRs created by workload agents.|
|glooMgmtServer.relay.signingTlsSecret.name|string|relay-tls-signing-secret||
|glooMgmtServer.relay.signingTlsSecret.namespace|string| ||
|glooMgmtServer.relay.tokenSecret|struct| |Secret containing a shared token for authenticating Gloo agents when they first communicate with the management server.|
|glooMgmtServer.relay.tokenSecret.name|string|relay-identity-token-secret|Name of the Kubernetes secret.|
|glooMgmtServer.relay.tokenSecret.namespace|string| |Namespace of the Kubernetes secret.|
|glooMgmtServer.relay.tokenSecret.key|string|token|Key value of the data within the Kubernetes secret.|
|glooMgmtServer.relay.disableCa|bool|false|To disable relay CA functionality, set to true. Set to true only when you supply your custom client certs to the agents for relay mTLS. The gloo-mesh-mgmt-server pod will not require a token secret or the signing cert secret. The agent pod will not require the token secret, but will fail without a client cert.|
|glooMgmtServer.relay.disableTokenGeneration|bool|false|Do not create the relay token Kubernetes secret. Set to true only when you supply own.|
|glooMgmtServer.relay.disableCaCertGeneration|bool|false|Do not auto-generate self-signed CA certificates. Set to true only when you supply own.|
|glooMgmtServer.relay.pushRbac|bool|true|Push RBAC resources to the management server. Required for multicluster RBAC in the Gloo UI.|
|glooMgmtServer.enabled|bool|false|Deploy the gloo-mesh-mgmt-server.|
|glooMgmtServer.maxGrpcMessageSize|string|4294967295|Maximum message size for gRPC messages sent and received by the management server.|
|glooMgmtServer.concurrency|uint16|10|Concurrency to use for translation operations.|
|glooMgmtServer.enableClusterLoadBalancing|bool|false|Experimental: Enable cluster load balancing. The management server replicas attempt to auto-balance the number of registered workload clusters, based on the number of replicas and the number of total clusters. For example, the server might disconnect a workload cluster if the number of connected clusters is greater than the allotted number.|
|glooMgmtServer.statsPort|uint32|9091|Port on the management server deployment to pull stats from.|
|glooMgmtServer.serviceAccount|struct| |Service account configuration to use for the management server deployment.|
|glooMgmtServer.serviceAccount.extraAnnotations|map[string, string]|null|Extra annotations to add to the service account.|
|glooMgmtServer.serviceAccount.extraAnnotations.<MAP_KEY>|string| |Extra annotations to add to the service account.|
|glooMgmtServer.cloudResourcesDiscovery|struct| |Configuration for automatic discovery of CloudResources.|
|glooMgmtServer.cloudResourcesDiscovery.enabled|bool|true|Enable automated discovery of CloudResources, such as AWS Lambda functions, based on CloudProvider configuration.|
|glooMgmtServer.cloudResourcesDiscovery.pollingInterval|uint16|10|Polling interval (in seconds) for calling AWS when attempting to discover CloudResources.|
|glooMgmtServer|struct| |Configuration for the glooMgmtServer deployment.|
|glooMgmtServer|struct| ||
|glooMgmtServer.image|struct| |Container image.|
|glooMgmtServer.image.tag|string| |Version tag for the container image.|
|glooMgmtServer.image.repository|string|gloo-mesh-mgmt-server|Image name (repository).|
|glooMgmtServer.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|glooMgmtServer.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|glooMgmtServer.image.pullSecret|string| |Image pull secret.|
|glooMgmtServer.env[]|slice|[{"name":"POD_NAMESPACE","valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}},{"name":"POD_UID","valueFrom":{"fieldRef":{"fieldPath":"metadata.uid"}}},{"name":"LICENSE_KEY","valueFrom":{"secretKeyRef":{"name":"gloo-mesh-enterprise-license","key":"key","optional":true}}},{"name":"REDIS_USERNAME","valueFrom":{"secretKeyRef":{"name":"redis-auth-secrets","key":"username","optional":true}}},{"name":"REDIS_PASSWORD","valueFrom":{"secretKeyRef":{"name":"redis-auth-secrets","key":"password","optional":true}}}]|Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooMgmtServer.resources|struct|{"requests":{"cpu":"125m","memory":"1Gi"}}|Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooMgmtServer.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooMgmtServer.sidecars|map[string, struct]|{}|Optional configuration for the deployed containers.|
|glooMgmtServer.sidecars.<MAP_KEY>|struct| |Optional configuration for the deployed containers.|
|glooMgmtServer.sidecars.<MAP_KEY>.image|struct| |Container image.|
|glooMgmtServer.sidecars.<MAP_KEY>.image.tag|string| |Version tag for the container image.|
|glooMgmtServer.sidecars.<MAP_KEY>.image.repository|string| |Image name (repository).|
|glooMgmtServer.sidecars.<MAP_KEY>.image.registry|string| |Image registry.|
|glooMgmtServer.sidecars.<MAP_KEY>.image.pullPolicy|string| |Image pull policy.|
|glooMgmtServer.sidecars.<MAP_KEY>.image.pullSecret|string| |Image pull secret.|
|glooMgmtServer.sidecars.<MAP_KEY>.env[]|slice| |Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooMgmtServer.sidecars.<MAP_KEY>.resources|struct| |Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooMgmtServer.sidecars.<MAP_KEY>.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooMgmtServer.floatingUserId|bool|false|Allow the pod to be assigned a dynamic user ID. Required for OpenShift installations.|
|glooMgmtServer.runAsUser|uint32|10101|Static user ID to run the containers as. Unused if floatingUserId is 'true'.|
|glooMgmtServer.serviceType|string|LoadBalancer|Kubernetes service type. Can be either "ClusterIP", "NodePort", "LoadBalancer", or "ExternalName".|
|glooMgmtServer.ports|map[string, uint32]|{"grpc":9900,"healthcheck":8090}|Service ports as a map from port name to port number.|
|glooMgmtServer.ports.<MAP_KEY>|uint32| |Service ports as a map from port name to port number.|
|glooMgmtServer.ports.grpc|uint32|9900|Service ports as a map from port name to port number.|
|glooMgmtServer.ports.healthcheck|uint32|8090|Service ports as a map from port name to port number.|
|glooMgmtServer.deploymentOverrides|struct| |Arbitrary overrides for the component's [deployment template](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)|
|glooMgmtServer.serviceOverrides|struct| |Arbitrary overrides for the component's [service template](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/).|
|glooMgmtServer.enabled|bool|true|Enable creation of the deployment/service.|
|glooAgent|struct| |Configuration for the glooAgent deployment.|
|glooAgent.enabled|bool|false|Deploy a Gloo agent to the cluster.|
|glooAgent|struct| |Configuration for the glooAgent deployment.|
|glooAgent|struct| ||
|glooAgent.image|struct| |Container image.|
|glooAgent.image.tag|string| |Version tag for the container image.|
|glooAgent.image.repository|string|gloo-mesh-agent|Image name (repository).|
|glooAgent.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|glooAgent.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|glooAgent.image.pullSecret|string| |Image pull secret.|
|glooAgent.env[]|slice|[{"name":"POD_NAMESPACE","valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}}]|Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooAgent.resources|struct|{"requests":{"cpu":"50m","memory":"128Mi"}}|Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooAgent.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooAgent.sidecars|map[string, struct]|{}|Optional configuration for the deployed containers.|
|glooAgent.sidecars.<MAP_KEY>|struct| |Optional configuration for the deployed containers.|
|glooAgent.sidecars.<MAP_KEY>.image|struct| |Container image.|
|glooAgent.sidecars.<MAP_KEY>.image.tag|string| |Version tag for the container image.|
|glooAgent.sidecars.<MAP_KEY>.image.repository|string| |Image name (repository).|
|glooAgent.sidecars.<MAP_KEY>.image.registry|string| |Image registry.|
|glooAgent.sidecars.<MAP_KEY>.image.pullPolicy|string| |Image pull policy.|
|glooAgent.sidecars.<MAP_KEY>.image.pullSecret|string| |Image pull secret.|
|glooAgent.sidecars.<MAP_KEY>.env[]|slice| |Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooAgent.sidecars.<MAP_KEY>.resources|struct| |Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooAgent.sidecars.<MAP_KEY>.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooAgent.floatingUserId|bool|false|Allow the pod to be assigned a dynamic user ID. Required for OpenShift installations.|
|glooAgent.runAsUser|uint32|10101|Static user ID to run the containers as. Unused if floatingUserId is 'true'.|
|glooAgent.serviceType|string|ClusterIP|Kubernetes service type. Can be either "ClusterIP", "NodePort", "LoadBalancer", or "ExternalName".|
|glooAgent.ports|map[string, uint32]|{"grpc":9977,"http":9988,"stats":9091}|Service ports as a map from port name to port number.|
|glooAgent.ports.<MAP_KEY>|uint32| |Service ports as a map from port name to port number.|
|glooAgent.ports.grpc|uint32|9977|Service ports as a map from port name to port number.|
|glooAgent.ports.http|uint32|9988|Service ports as a map from port name to port number.|
|glooAgent.ports.stats|uint32|9091|Service ports as a map from port name to port number.|
|glooAgent.deploymentOverrides|struct| |Arbitrary overrides for the component's [deployment template](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)|
|glooAgent.serviceOverrides|struct| |Arbitrary overrides for the component's [service template](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/).|
|glooAgent.enabled|bool|true|Enable creation of the deployment/service.|
|glooUi|struct| |Configuration for the glooUi deployment.|
|glooUi|struct| ||
|glooUi.prometheusUrl|string| |Prometheus server address.|
|glooUi|struct| ||
|glooUi.verbose|bool|false|Enable verbose/debug logging.|
|glooUi|struct| ||
|glooUi.readOnlyGeneratedResources|bool|false|If true, the deployment only reads Istio resource outputs that are created by Gloo Platform, and filters out Istio resource fields that Gloo Mesh cannot properly unmarshal. These other resource outputs are not visible in the Gloo UI.|
|glooUi.enabled|bool|false|Deploy the gloo-mesh-ui.|
|glooUi.settingsName|string|settings|Name of the UI settings object to use.|
|glooUi.auth|struct| |Configure authentication for the UI.|
|glooUi.auth.enabled|bool|false|Require authentication to access the UI.|
|glooUi.auth.backend|string| |Authentication backend to use. 'oidc' is supported.|
|glooUi.auth.oidc|struct| |Settings for the OpenID Connect (OIDC) backend.|
|glooUi.auth.oidc.clientId|string| |OIDC client ID|
|glooUi.auth.oidc.clientSecret|string| |Plaintext OIDC client secret, which will be encoded in base64 and stored in a secret named the value of 'clientSecretName'.|
|glooUi.auth.oidc.clientSecretName|string| |Name for the secret that will contain the client secret.|
|glooUi.auth.oidc.issuerUrl|string| |Issuer URL from the OIDC provider, such as 'https://<domain>.<provider_url>/'.|
|glooUi.auth.oidc.appUrl|string| |URL that the UI for OIDC app is available at, from the DNS and other ingress settings that expose OIDC app UI service.|
|glooUi.auth.oidc.session|struct| |Session storage configuration. If omitted, a cookie is used.|
|glooUi.auth.oidc.session.backend|string| |Backend to use for auth session storage. 'cookie' and 'redis' are supported.|
|glooUi.auth.oidc.session.redis|struct| |Redis instance configuration.|
|glooUi.auth.oidc.session.redis.host|string| |Host at which the Redis instance is accessible. To use the default Redis deployment, specify 'redis.gloo-mesh.svc.cluster.local:6379'.|
|glooUi.licenseSecretName|string| |Provide license keys in a secret in the adminNamespace of the management cluster, instead of in the license key fields.|
|glooUi|struct| |Configuration for the glooUi deployment.|
|glooUi|struct| ||
|glooUi.image|struct| |Container image.|
|glooUi.image.tag|string| |Version tag for the container image.|
|glooUi.image.repository|string|gloo-mesh-apiserver|Image name (repository).|
|glooUi.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|glooUi.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|glooUi.image.pullSecret|string| |Image pull secret.|
|glooUi.env[]|slice|[{"name":"POD_NAMESPACE","valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}},{"name":"LICENSE_KEY","valueFrom":{"secretKeyRef":{"name":"gloo-mesh-enterprise-license","key":"key","optional":true}}},{"name":"REDIS_USERNAME","valueFrom":{"secretKeyRef":{"name":"redis-auth-secrets","key":"username","optional":true}}},{"name":"REDIS_PASSWORD","valueFrom":{"secretKeyRef":{"name":"redis-auth-secrets","key":"password","optional":true}}}]|Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooUi.resources|struct|{"requests":{"cpu":"125m","memory":"256Mi"}}|Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooUi.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooUi.sidecars|map[string, struct]|{"console":{"image":{"repository":"gloo-mesh-ui","registry":"gcr.io/gloo-mesh","pullPolicy":"IfNotPresent"},"env":null,"resources":{"requests":{"cpu":"125m","memory":"256Mi"}}},"envoy":{"image":{"repository":"gloo-mesh-envoy","registry":"gcr.io/gloo-mesh","pullPolicy":"IfNotPresent"},"env":[{"name":"ENVOY_UID","value":"0"}],"resources":{"requests":{"cpu":"500m","memory":"256Mi"}}}}|Optional configuration for the deployed containers.|
|glooUi.sidecars.<MAP_KEY>|struct| |Optional configuration for the deployed containers.|
|glooUi.sidecars.<MAP_KEY>.image|struct| |Container image.|
|glooUi.sidecars.<MAP_KEY>.image.tag|string| |Version tag for the container image.|
|glooUi.sidecars.<MAP_KEY>.image.repository|string| |Image name (repository).|
|glooUi.sidecars.<MAP_KEY>.image.registry|string| |Image registry.|
|glooUi.sidecars.<MAP_KEY>.image.pullPolicy|string| |Image pull policy.|
|glooUi.sidecars.<MAP_KEY>.image.pullSecret|string| |Image pull secret.|
|glooUi.sidecars.<MAP_KEY>.env[]|slice| |Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooUi.sidecars.<MAP_KEY>.resources|struct| |Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooUi.sidecars.<MAP_KEY>.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooUi.sidecars.console|struct| |Optional configuration for the deployed containers.|
|glooUi.sidecars.console.image|struct| |Container image.|
|glooUi.sidecars.console.image.tag|string| |Version tag for the container image.|
|glooUi.sidecars.console.image.repository|string|gloo-mesh-ui|Image name (repository).|
|glooUi.sidecars.console.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|glooUi.sidecars.console.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|glooUi.sidecars.console.image.pullSecret|string| |Image pull secret.|
|glooUi.sidecars.console.env[]|slice|null|Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooUi.sidecars.console.resources|struct|{"requests":{"cpu":"125m","memory":"256Mi"}}|Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooUi.sidecars.console.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooUi.sidecars.envoy|struct| |Optional configuration for the deployed containers.|
|glooUi.sidecars.envoy.image|struct| |Container image.|
|glooUi.sidecars.envoy.image.tag|string| |Version tag for the container image.|
|glooUi.sidecars.envoy.image.repository|string|gloo-mesh-envoy|Image name (repository).|
|glooUi.sidecars.envoy.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|glooUi.sidecars.envoy.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|glooUi.sidecars.envoy.image.pullSecret|string| |Image pull secret.|
|glooUi.sidecars.envoy.env[]|slice|[{"name":"ENVOY_UID","value":"0"}]|Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooUi.sidecars.envoy.resources|struct|{"requests":{"cpu":"500m","memory":"256Mi"}}|Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooUi.sidecars.envoy.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooUi.floatingUserId|bool|false|Allow the pod to be assigned a dynamic user ID. Required for OpenShift installations.|
|glooUi.runAsUser|uint32|10101|Static user ID to run the containers as. Unused if floatingUserId is 'true'.|
|glooUi.serviceType|string|ClusterIP|Kubernetes service type. Can be either "ClusterIP", "NodePort", "LoadBalancer", or "ExternalName".|
|glooUi.ports|map[string, uint32]|{"console":8090,"grpc":10101,"healthcheck":8081}|Service ports as a map from port name to port number.|
|glooUi.ports.<MAP_KEY>|uint32| |Service ports as a map from port name to port number.|
|glooUi.ports.console|uint32|8090|Service ports as a map from port name to port number.|
|glooUi.ports.grpc|uint32|10101|Service ports as a map from port name to port number.|
|glooUi.ports.healthcheck|uint32|8081|Service ports as a map from port name to port number.|
|glooUi.deploymentOverrides|struct| |Arbitrary overrides for the component's [deployment template](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)|
|glooUi.serviceOverrides|struct| |Arbitrary overrides for the component's [service template](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/).|
|glooUi.enabled|bool|true|Enable creation of the deployment/service.|
|redis.deployment|struct| |Configuration for the deployment deployment.|
|redis.deployment.enabled|bool|true|Deploy the default Redis instance.|
|redis.deployment.addr|string| |Deprecated: Use 'redis.address' instead.|
|redis.deployment|struct| |Configuration for the deployment deployment.|
|redis.deployment|struct| ||
|redis.deployment.image|struct| |Container image.|
|redis.deployment.image.tag|string| |Version tag for the container image.|
|redis.deployment.image.repository|string|redis|Image name (repository).|
|redis.deployment.image.registry|string|docker.io|Image registry.|
|redis.deployment.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|redis.deployment.image.pullSecret|string| |Image pull secret.|
|redis.deployment.env[]|slice|[{"name":"MASTER","value":"true"}]|Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|redis.deployment.resources|struct|{"requests":{"cpu":"125m","memory":"256Mi"}}|Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|redis.deployment.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|redis.deployment.sidecars|map[string, struct]|{}|Optional configuration for the deployed containers.|
|redis.deployment.sidecars.<MAP_KEY>|struct| |Optional configuration for the deployed containers.|
|redis.deployment.sidecars.<MAP_KEY>.image|struct| |Container image.|
|redis.deployment.sidecars.<MAP_KEY>.image.tag|string| |Version tag for the container image.|
|redis.deployment.sidecars.<MAP_KEY>.image.repository|string| |Image name (repository).|
|redis.deployment.sidecars.<MAP_KEY>.image.registry|string| |Image registry.|
|redis.deployment.sidecars.<MAP_KEY>.image.pullPolicy|string| |Image pull policy.|
|redis.deployment.sidecars.<MAP_KEY>.image.pullSecret|string| |Image pull secret.|
|redis.deployment.sidecars.<MAP_KEY>.env[]|slice| |Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|redis.deployment.sidecars.<MAP_KEY>.resources|struct| |Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|redis.deployment.sidecars.<MAP_KEY>.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|redis.deployment.floatingUserId|bool|false|Allow the pod to be assigned a dynamic user ID. Required for OpenShift installations.|
|redis.deployment.runAsUser|uint32|10101|Static user ID to run the containers as. Unused if floatingUserId is 'true'.|
|redis.deployment.serviceType|string|ClusterIP|Kubernetes service type. Can be either "ClusterIP", "NodePort", "LoadBalancer", or "ExternalName".|
|redis.deployment.ports|map[string, uint32]|{"redis":6379}|Service ports as a map from port name to port number.|
|redis.deployment.ports.<MAP_KEY>|uint32| |Service ports as a map from port name to port number.|
|redis.deployment.ports.redis|uint32|6379|Service ports as a map from port name to port number.|
|redis.deployment.deploymentOverrides|struct| |Arbitrary overrides for the component's [deployment template](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)|
|redis.deployment.serviceOverrides|struct| |Arbitrary overrides for the component's [service template](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/).|
|redis.deployment.enabled|bool|true|Enable creation of the deployment/service.|
|glooPortalServer|struct| |Configuration for the glooPortalServer deployment.|
|glooPortalServer|struct| ||
|glooPortalServer.verbose|bool|false|Enable verbose/debug logging.|
|glooPortalServer|struct| ||
|glooPortalServer.devMode|bool|false|Set to true to enable development mode for the logger, which can cause panics. Do not use in production.|
|glooPortalServer.enabled|bool|false|Deploy the Portal server for Gloo Platform Portal to the cluster.|
|glooPortalServer.apiKeyStorage|struct| ||
|glooPortalServer.apiKeyStorage.type|string|redis|Backend storage for API keys. Supported values: "redis"|
|glooPortalServer.apiKeyStorage.configPath|string|/etc/apikeys/storage-config.yaml|Path for API key storage config file|
|glooPortalServer.apiKeyStorage.secretKey|string|change this||
|glooPortalServer|struct| |Configuration for the glooPortalServer deployment.|
|glooPortalServer|struct| ||
|glooPortalServer.image|struct| |Container image.|
|glooPortalServer.image.tag|string| |Version tag for the container image.|
|glooPortalServer.image.repository|string|gloo-mesh-portal-server|Image name (repository).|
|glooPortalServer.image.registry|string|gcr.io/gloo-mesh|Image registry.|
|glooPortalServer.image.pullPolicy|string|IfNotPresent|Image pull policy.|
|glooPortalServer.image.pullSecret|string| |Image pull secret.|
|glooPortalServer.env[]|slice|[{"name":"POD_NAMESPACE","valueFrom":{"fieldRef":{"fieldPath":"metadata.namespace"}}},{"name":"APIKEY_STORAGE_SECRET_KEY","valueFrom":{"secretKeyRef":{"name":"portal-storage-secret-key","key":"key"}}}]|Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooPortalServer.resources|struct|{"requests":{"cpu":"50m","memory":"128Mi"}}|Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooPortalServer.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooPortalServer.sidecars|map[string, struct]|{}|Optional configuration for the deployed containers.|
|glooPortalServer.sidecars.<MAP_KEY>|struct| |Optional configuration for the deployed containers.|
|glooPortalServer.sidecars.<MAP_KEY>.image|struct| |Container image.|
|glooPortalServer.sidecars.<MAP_KEY>.image.tag|string| |Version tag for the container image.|
|glooPortalServer.sidecars.<MAP_KEY>.image.repository|string| |Image name (repository).|
|glooPortalServer.sidecars.<MAP_KEY>.image.registry|string| |Image registry.|
|glooPortalServer.sidecars.<MAP_KEY>.image.pullPolicy|string| |Image pull policy.|
|glooPortalServer.sidecars.<MAP_KEY>.image.pullSecret|string| |Image pull secret.|
|glooPortalServer.sidecars.<MAP_KEY>.env[]|slice| |Environment variables for the container. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#envvarsource-v1-core).|
|glooPortalServer.sidecars.<MAP_KEY>.resources|struct| |Container resource requirements. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#resourcerequirements-v1-core).|
|glooPortalServer.sidecars.<MAP_KEY>.securityContext|struct| |Container security context. Set to 'false' to omit the security context entirely. For more info, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#securitycontext-v1-core).|
|glooPortalServer.floatingUserId|bool|false|Allow the pod to be assigned a dynamic user ID. Required for OpenShift installations.|
|glooPortalServer.runAsUser|uint32|10101|Static user ID to run the containers as. Unused if floatingUserId is 'true'.|
|glooPortalServer.serviceType|string|ClusterIP|Kubernetes service type. Can be either "ClusterIP", "NodePort", "LoadBalancer", or "ExternalName".|
|glooPortalServer.ports|map[string, uint32]|{"http":8080}|Service ports as a map from port name to port number.|
|glooPortalServer.ports.<MAP_KEY>|uint32| |Service ports as a map from port name to port number.|
|glooPortalServer.ports.http|uint32|8080|Service ports as a map from port name to port number.|
|glooPortalServer.deploymentOverrides|struct| |Arbitrary overrides for the component's [deployment template](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)|
|glooPortalServer.serviceOverrides|struct| |Arbitrary overrides for the component's [service template](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/).|
|glooPortalServer.enabled|bool|true|Enable creation of the deployment/service.|
