# Debug traffic flow with istioctl

## Summary of commands used

```bash
# get the route details
# Field: `filterChains.filters[].typedConfig.rds.routeConfigName`
istioctl pc listeners [podname].[namespace] --port [port_that_you_are_attempting_to_Access] -o json | less

# get the cluster details associated with the route
# `virtualHosts[].routes.route.cluster`
istioctl pc route [podname].[namespace] --name [route_that_you_are_attempting_to_Access] -o json | less

# Get the destination details. 
# Field: `edsClusterConfig.serviceName`
istioctl pc clusters [podname].[namespace] --fqdn '[envoy_cluster]' -o json | less
```

```bash
# To get the envoy-stats such as rq_total, cx_total, rq_error etc. 
istioctl x envoy-stats [podname].[namespace] --type clusters | grep [envoy_cluster_name]
e.g. 
istioctl x envoy-stats istio-ingressgateway-f67cb867d-9mk69.istio-gateways --type clusters | grep 'productpage.global'
istioctl x envoy-stats istio-ingressgateway-f67cb867d-2whzj.istio-gateways --type clusters | grep 'productpage.global' | grep 'rq_error'
istioctl x envoy-stats istio-ingressgateway-f67cb867d-2whzj.istio-gateways --type clusters | grep 'productpage.global' | grep 'rq_success'

istioctl x envoy-stats -n istio-gateways deploy/istio-ingressgateway --type clusters | grep 'productpage.global' | grep 'rq_success'
istioctl x envoy-stats -n istio-gateways deploy/istio-ingressgateway --type clusters | grep 'productpage.global' | grep 'rq_error'
```

```bash
# 1. summary of endpoints for the envoy cluster
istioctl pc endpoints --cluster "outbound|9080||productpage.global" -n istio-gateways deploy/istio-ingressgateway

# 2. more detailed info on the envoy cluster
istioctl pc endpoints --cluster "outbound|9080||productpage.global" -n istio-gateways deploy/istio-ingressgateway -o yaml

# Example output for 1:
ENDPOINT                STATUS      OUTLIER CHECK     CLUSTER
10.128.2.112:9080       HEALTHY     OK                outbound|9080||productpage.global
3.222.170.192:15443     HEALTHY     OK                outbound|9080||productpage.global
3.226.201.88:15443      HEALTHY     OK                outbound|9080||productpage.global
35.167.16.0:15443       HEALTHY     OK                outbound|9080||productpage.global
52.27.163.189:15443     HEALTHY     OK                outbound|9080||productpage.global
52.54.196.35:15443      HEALTHY     OK                outbound|9080||productpage.global


```

# Example debug scenario

sleep pod running in `client-namespace` is attempting to reach nginx with label `instance: a` in the `server-namespace` and getting a 503

## istioctl pc listeners example

```bash
istioctl pc listeners sleep-6ffdd98f9f-whbbr.client-namespace --port 80 -o json | less
```
We look for the right route name in the following output so that we can run the next command (`istioctl pc route`) with the right route name.

> Field to look for `filterChains.filters[].typedConfig.rds.routeConfigName`

### Sample output of `istioctl pc listeners`:
```json
[
    {
        "name": "0.0.0.0_80",
        "address": {
            "socketAddress": {
                "address": "0.0.0.0",
                "portValue": 80
            }
        },
        "filterChains": [
            {
                "filterChainMatch": {
                    "transportProtocol": "raw_buffer",
                    "applicationProtocols": [
                        "http/1.1",
                        "h2c"
                    ]
                },
                "filters": [
                    {
                        "name": "envoy.filters.network.http_connection_manager",
                        "typedConfig": {
                            "@type": "type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager",
                            "statPrefix": "outbound_0.0.0.0_80",
                            "rds": {
                                "configSource": {
                                    "ads": {},
                                    "initialFetchTimeout": "0s",
                                    "resourceApiVersion": "V3"
                                },
                                "routeConfigName": "80"
                            },
                            "httpFilters": [
                                {
                                    "name": "istio.metadata_exchange",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                                        "config": {
                                            "vmConfig": {
                                                "runtime": "envoy.wasm.runtime.null",
                                                "code": {
                                                    "local": {
                                                        "inlineString": "envoy.wasm.metadata_exchange"
                                                    }
                                                }
                                            },
                                            "configuration": {
                                                "@type": "type.googleapis.com/envoy.tcp.metadataexchange.config.MetadataExchange"
                                            }
                                        }
                                    }
                                },
                                {
                                    "name": "istio.alpn",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/istio.envoy.config.filter.http.alpn.v2alpha1.FilterConfig",
                                        "alpnOverride": [
                                            {
                                                "alpnOverride": [
                                                    "istio-http/1.0",
                                                    "istio",
                                                    "http/1.0"
                                                ]
                                            },
                                            {
                                                "upstreamProtocol": "HTTP11",
                                                "alpnOverride": [
                                                    "istio-http/1.1",
                                                    "istio",
                                                    "http/1.1"
                                                ]
                                            },
                                            {
                                                "upstreamProtocol": "HTTP2",
                                                "alpnOverride": [
                                                    "istio-h2",
                                                    "istio",
                                                    "h2"
                                                ]
                                            }
                                        ]
                                    }
                                },
                                {
                                    "name": "envoy.filters.http.fault",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.extensions.filters.http.fault.v3.HTTPFault"
                                    }
                                },
                                {
                                    "name": "envoy.filters.http.cors",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.extensions.filters.http.cors.v3.Cors"
                                    }
                                },
                                {
                                    "name": "istio.stats",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/udpa.type.v1.TypedStruct",
                                        "typeUrl": "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                                        "value": {
                                            "config": {
                                                "configuration": {
                                                    "@type": "type.googleapis.com/google.protobuf.StringValue",
                                                    "value": "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                                                },
                                                "root_id": "stats_outbound",
                                                "vm_config": {
                                                    "code": {
                                                        "local": {
                                                            "inline_string": "envoy.wasm.stats"
                                                        }
                                                    },
                                                    "runtime": "envoy.wasm.runtime.null",
                                                    "vm_id": "stats_outbound"
                                                }
                                            }
                                        }
                                    }
                                },
                                {
                                    "name": "envoy.filters.http.router",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.extensions.filters.http.router.v3.Router"
                                    }
                                }
                            ],
                            "tracing": {
                                "clientSampling": {
                                    "value": 100
                                },
                                "randomSampling": {
                                    "value": 1
                                },
                                "overallSampling": {
                                    "value": 100
                                },
                                "customTags": [
                                    {
                                        "tag": "istio.authorization.dry_run.allow_policy.name",
                                        "metadata": {
                                            "kind": {
                                                "request": {}
                                            },
                                            "metadataKey": {
                                                "key": "envoy.filters.http.rbac",
                                                "path": [
                                                    {
                                                        "key": "istio_dry_run_allow_shadow_effective_policy_id"
                                                    }
                                                ]
                                            }
                                        }
                                    },
                                    {
                                        "tag": "istio.authorization.dry_run.allow_policy.result",
                                        "metadata": {
                                            "kind": {
                                                "request": {}
                                            },
                                            "metadataKey": {
                                                "key": "envoy.filters.http.rbac",
                                                "path": [
                                                    {
                                                        "key": "istio_dry_run_allow_shadow_engine_result"
                                                    }
                                                ]
                                            }
                                        }
                                    },
                                    {
                                        "tag": "istio.authorization.dry_run.deny_policy.name",
                                        "metadata": {
                                            "kind": {
                                                "request": {}
                                            },
                                            "metadataKey": {
                                                "key": "envoy.filters.http.rbac",
                                                "path": [
                                                    {
                                                        "key": "istio_dry_run_deny_shadow_effective_policy_id"
                                                    }
                                                ]
                                            }
                                        }
                                    },
                                    {
                                        "tag": "istio.authorization.dry_run.deny_policy.result",
                                        "metadata": {
                                            "kind": {
                                                "request": {}
                                            },
                                            "metadataKey": {
                                                "key": "envoy.filters.http.rbac",
                                                "path": [
                                                    {
                                                        "key": "istio_dry_run_deny_shadow_engine_result"
                                                    }
                                                ]
                                            }
                                        }
                                    },
                                    {
                                        "tag": "istio.canonical_revision",
                                        "literal": {
                                            "value": "latest"
                                        }
                                    },
                                    {
                                        "tag": "istio.canonical_service",
                                        "literal": {
                                            "value": "sleep"
                                        }
                                    },
                                    {
                                        "tag": "istio.mesh_id",
                                        "literal": {
                                            "value": "mesh1"
                                        }
                                    },
                                    {
                                        "tag": "istio.namespace",
                                        "literal": {
                                            "value": "client-namespace"
                                        }
                                    }
                                ]
                            },
                            "streamIdleTimeout": "0s",
                            "accessLog": [
                                {
                                    "name": "envoy.access_loggers.file",
                                    "typedConfig": {
                                        "@type": "type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog",
                                        "path": "/dev/stdout",
                                        "logFormat": {
                                            "textFormatSource": {
                                                "inlineString": "[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS% \"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\" \"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n"
                                            }
                                        }
                                    }
                                }
                            ],
                            "useRemoteAddress": false,
                            "upgradeConfigs": [
                                {
                                    "upgradeType": "websocket"
                                }
                            ],
                            "normalizePath": true,
                            "pathWithEscapedSlashesAction": "KEEP_UNCHANGED",
                            "requestIdExtension": {
                                "typedConfig": {
                                    "@type": "type.googleapis.com/envoy.extensions.request_id.uuid.v3.UuidRequestIdConfig",
                                    "useRequestIdForTraceSampling": true
                                }
                            }
                        }
                    }
                ]
            }
        ],
        "defaultFilterChain": {
            "filterChainMatch": {},
            "filters": [
                {
                    "name": "istio.stats",
                    "typedConfig": {
                        "@type": "type.googleapis.com/udpa.type.v1.TypedStruct",
                        "typeUrl": "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                        "value": {
                            "config": {
                                "configuration": {
                                    "@type": "type.googleapis.com/google.protobuf.StringValue",
                                    "value": "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                                },
                                "root_id": "stats_outbound",
                                "vm_config": {
                                    "code": {
                                        "local": {
                                            "inline_string": "envoy.wasm.stats"
                                        }
                                    },
                                    "runtime": "envoy.wasm.runtime.null",
                                    "vm_id": "tcp_stats_outbound"
                                }
                            }
                        }
                    }
                },
                {
                    "name": "envoy.filters.network.tcp_proxy",
                    "typedConfig": {
                        "@type": "type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy",
                        "statPrefix": "BlackHoleCluster",
                        "cluster": "BlackHoleCluster",
                        "accessLog": [
                            {
                                "name": "envoy.access_loggers.file",
                                "typedConfig": {
                                    "@type": "type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog",
                                    "path": "/dev/stdout",
                                    "logFormat": {
                                        "textFormatSource": {
                                            "inlineString": "[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS% \"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\" \"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n"
                                        }
                                    }
                                }
                            }
                        ]
                    }
                }
            ],
            "name": "PassthroughFilterChain"
        },
        "listenerFilters": [
            {
                "name": "envoy.filters.listener.tls_inspector",
                "typedConfig": {
                    "@type": "type.googleapis.com/envoy.extensions.filters.listener.tls_inspector.v3.TlsInspector"
                }
            },
            {
                "name": "envoy.filters.listener.http_inspector",
                "typedConfig": {
                    "@type": "type.googleapis.com/envoy.extensions.filters.listener.http_inspector.v3.HttpInspector"
                }
            }
        ],
        "listenerFiltersTimeout": "0s",
        "continueOnListenerFiltersTimeout": true,
        "trafficDirection": "OUTBOUND",
        "accessLog": [
            {
                "name": "envoy.access_loggers.file",
                "filter": {
                    "responseFlagFilter": {
                        "flags": [
                            "NR"
                        ]
                    }
                },
                "typedConfig": {
                    "@type": "type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog",
                    "path": "/dev/stdout",
                    "logFormat": {
                        "textFormatSource": {
                            "inlineString": "[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS% \"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\" \"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n"
                        }
                    }
                }
            }
        ],
        "bindToPort": false
    }
]
```

## istioctl pc route example

```bash
istioctl pc route sleep-6ffdd98f9f-whbbr.client-namespace --name 80 -o json | less
```

- In the `virtualHosts[]` we look for our target domain.
- In our example scenario we were trying to reach nginx via `nginx.server-namespace.svc.cluster.local:80`
- Then we look for the cluster name.

> Field to look for: `virtualHosts[].routes.route.cluster`

We get the `routes.route.cluster` from the output i.e. `"outbound|80|instance-a|nginx.server-namespace.svc.cluster.local"` and we use the same in the following command (`istioctl pc clusters`)

### Sample output of `istioctl pc route`

```json
[
    {
        "name": "80",
        "virtualHosts": [
            {
                "name": "block_all",
                "domains": [
                    "*"
                ],
                "routes": [
                    {
                        "name": "block_all",
                        "match": {
                            "prefix": "/"
                        },
                        "directResponse": {
                            "status": 502
                        }
                    }
                ],
                "includeRequestAttemptCount": true
            },
            {
                "name": "nginx.server-namespace.svc.cluster.local:80",
                "domains": [
                    "nginx.server-namespace.svc.cluster.local",
                    "nginx.server-namespace",
                    "nginx.server-namespace.svc",
                    "172.20.211.155"
                ],
                "routes": [
                    {
                        "name": "nginx-sleep-to-nginx-route.client-namespace.mgmt-cluster-arka",
                        "match": {
                            "prefix": "/",
                            "caseSensitive": true
                        },
                        "route": {
                            "cluster": "outbound|80|instance-a|nginx.server-namespace.svc.cluster.local",
                            "timeout": "0s",
                            "retryPolicy": {
                                "retryOn": "connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes",
                                "numRetries": 2,
                                "retryHostPredicate": [
                                    {
                                        "name": "envoy.retry_host_predicates.previous_hosts",
                                        "typedConfig": {
                                            "@type": "type.googleapis.com/envoy.extensions.retry.host.previous_hosts.v3.PreviousHostsPredicate"
                                        }
                                    }
                                ],
                                "hostSelectionRetryMaxAttempts": "5",
                                "retriableStatusCodes": [
                                    503
                                ]
                            },
                            "maxGrpcTimeout": "0s"
                        },
                        "metadata": {
                            "filterMetadata": {
                                "istio": {
                                    "config": "/apis/networking.istio.io/v1alpha3/namespaces/client-namespace/virtual-service/routetable-sleep-to-nginx-route-5fabad37c1396da73c9aaed6fb8ed06"
                                }
                            }
                        },
                        "decorator": {
                            "operation": "nginx.server-namespace.svc.cluster.local:80/*"
                        }
                    }
                ],
                "includeRequestAttemptCount": true
            },
            {
                "name": "sleep.client-namespace.svc.cluster.local:80",
                "domains": [
                    "sleep.client-namespace.svc.cluster.local",
                    "sleep",
                    "sleep.client-namespace.svc",
                    "sleep.client-namespace",
                    "172.20.25.70"
                ],
                "routes": [
                    {
                        "name": "default",
                        "match": {
                            "prefix": "/"
                        },
                        "route": {
                            "cluster": "outbound|80||sleep.client-namespace.svc.cluster.local",
                            "timeout": "0s",
                            "retryPolicy": {
                                "retryOn": "connect-failure,refused-stream,unavailable,cancelled,retriable-status-codes",
                                "numRetries": 2,
                                "retryHostPredicate": [
                                    {
                                        "name": "envoy.retry_host_predicates.previous_hosts",
                                        "typedConfig": {
                                            "@type": "type.googleapis.com/envoy.extensions.retry.host.previous_hosts.v3.PreviousHostsPredicate"
                                        }
                                    }
                                ],
                                "hostSelectionRetryMaxAttempts": "5",
                                "retriableStatusCodes": [
                                    503
                                ]
                            },
                            "maxGrpcTimeout": "0s"
                        },
                        "decorator": {
                            "operation": "sleep.client-namespace.svc.cluster.local:80/*"
                        }
                    }
                ],
                "includeRequestAttemptCount": true
            }
        ],
        "validateClusters": false,
        "ignorePortInHostMatching": true
    }
]
```

## istioctl pc clusters example

```bash
istioctl pc clusters sleep-6ffdd98f9f-whbbr.client-namespace --fqdn 'outbound|80|instance-a|nginx.server-namespace.svc.cluster.local' -o json | less
```

- The output for us was empty. WHich indicated the problem that we were debugging.
- Then we started looking at the output **without** the `--fqdn` flag: `istioctl pc clusters sleep-6ffdd98f9f-whbbr.client-namespace`

### Sample output of istioctl pc clusters without the --fqdn

```bash
SERVICE FQDN                                 PORT     SUBSET     DIRECTION     TYPE             DESTINATION RULE
                                             80       -          inbound       ORIGINAL_DST
BlackHoleCluster                             -        -          -             STATIC
InboundPassthroughClusterIpv4                -        -          -             ORIGINAL_DST
PassthroughCluster                           -        -          -             ORIGINAL_DST
agent                                        -        -          -             STATIC
envoy_accesslog_service                      -        -          -             STRICT_DNS
envoy_metrics_service                        -        -          -             STRICT_DNS
nginx.server-namespace.svc.cluster.local     80       -          outbound      EDS
prometheus_stats                             -        -          -             STATIC
sds-grpc                                     -        -          -             STATIC
sleep.client-namespace.svc.cluster.local     80       -          outbound      EDS
xds-grpc                                     -        -          -             STATIC
zipkin                                       -        -          -             STRICT_DNS
```

- At this point, we started looking at whether the `DestinationRule` and the `VirtualService` was present in the namespace from where we were calling
- We found that the `DestinationRule` was missing in the source namespace.

### Manual step to validate the missing piece

- We manually created the following `DestinationRule`
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: nginx-client-namespace-test
  namespace: client-namespace
spec:
  exportTo:
  - .
  host: nginx.server-namespace.svc.cluster.local
  subsets:
  - labels:
      instance: a
    name: instance-a
  - labels:
      instance: b
    name: instance-b
```

- We re-ran the `istioctl pc clusters` with `--fqdn` and got the desired output instead of an empty object.

### Sample output of istioctl pc clusters with the --fqdn

```bash
istioctl pc clusters sleep-6ffdd98f9f-whbbr.client-namespace \
    --fqdn 'outbound|80|instance-a|nginx.server-namespace.svc.cluster.local' \
    -o json | less
```

> Field to look for: `edsClusterConfig.serviceName`

```json
[
    {
        "transportSocketMatches": [
            {
                "name": "tlsMode-istio",
                "match": {
                    "tlsMode": "istio"
                },
                "transportSocket": {
                    "name": "envoy.transport_sockets.tls",
                    "typedConfig": {
                        "@type": "type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext",
                        "commonTlsContext": {
                            "tlsParams": {
                                "tlsMinimumProtocolVersion": "TLSv1_2",
                                "tlsMaximumProtocolVersion": "TLSv1_3"
                            },
                            "tlsCertificateSdsSecretConfigs": [
                                {
                                    "name": "default",
                                    "sdsConfig": {
                                        "apiConfigSource": {
                                            "apiType": "GRPC",
                                            "transportApiVersion": "V3",
                                            "grpcServices": [
                                                {
                                                    "envoyGrpc": {
                                                        "clusterName": "sds-grpc"
                                                    }
                                                }
                                            ],
                                            "setNodeOnFirstMessageOnly": true
                                        },
                                        "initialFetchTimeout": "0s",
                                        "resourceApiVersion": "V3"
                                    }
                                }
                            ],
                            "combinedValidationContext": {
                                "defaultValidationContext": {
                                    "matchSubjectAltNames": [
                                        {
                                            "exact": "spiffe://cluster-1-arka/ns/server-namespace/sa/nginx"
                                        }
                                    ]
                                },
                                "validationContextSdsSecretConfig": {
                                    "name": "ROOTCA",
                                    "sdsConfig": {
                                        "apiConfigSource": {
                                            "apiType": "GRPC",
                                            "transportApiVersion": "V3",
                                            "grpcServices": [
                                                {
                                                    "envoyGrpc": {
                                                        "clusterName": "sds-grpc"
                                                    }
                                                }
                                            ],
                                            "setNodeOnFirstMessageOnly": true
                                        },
                                        "initialFetchTimeout": "0s",
                                        "resourceApiVersion": "V3"
                                    }
                                }
                            },
                            "alpnProtocols": [
                                "istio-peer-exchange",
                                "istio"
                            ]
                        },
                        "sni": "outbound_.80_.instance-a_.nginx.server-namespace.svc.cluster.local"
                    }
                }
            },
            {
                "name": "tlsMode-disabled",
                "match": {},
                "transportSocket": {
                    "name": "envoy.transport_sockets.raw_buffer",
                    "typedConfig": {
                        "@type": "type.googleapis.com/envoy.extensions.transport_sockets.raw_buffer.v3.RawBuffer"
                    }
                }
            }
        ],
        "name": "outbound|80|instance-a|nginx.server-namespace.svc.cluster.local",
        "type": "EDS",
        "edsClusterConfig": {
            "edsConfig": {
                "ads": {},
                "initialFetchTimeout": "0s",
                "resourceApiVersion": "V3"
            },
            "serviceName": "outbound|80|instance-a|nginx.server-namespace.svc.cluster.local"
        },
        "connectTimeout": "10s",
        "lbPolicy": "LEAST_REQUEST",
        "circuitBreakers": {
            "thresholds": [
                {
                    "maxConnections": 4294967295,
                    "maxPendingRequests": 4294967295,
                    "maxRequests": 4294967295,
                    "maxRetries": 4294967295,
                    "trackRemaining": true
                }
            ]
        },
        "commonLbConfig": {
            "localityWeightedLbConfig": {}
        },
        "metadata": {
            "filterMetadata": {
                "istio": {
                    "config": "/apis/networking.istio.io/v1alpha3/namespaces/client-namespace/destination-rule/nginx-client-namespace-test",
                    "default_original_port": 80,
                    "services": [
                        {
                            "host": "nginx.server-namespace.svc.cluster.local",
                            "name": "nginx",
                            "namespace": "server-namespace"
                        }
                    ],
                    "subset": "instance-a"
                }
            }
        },
        "filters": [
            {
                "name": "istio.metadata_exchange",
                "typedConfig": {
                    "@type": "type.googleapis.com/envoy.tcp.metadataexchange.config.MetadataExchange",
                    "protocol": "istio-peer-exchange"
                }
            }
        ]
    }
]
```
