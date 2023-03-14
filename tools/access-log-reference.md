

Access log entry from an east-west gateway pod. (Istio 1.14+)
![alt text](https://github.com/[username]/[reponame]/blob/[branch]/image.jpg?raw=true)

Example: 
```
k logs istio-eastwestgateway-668485ccb6-xfjxm -n istio-gateways`
```
Access Log entry
```
{
  "authority": null,
  "bytes_received": 8829,
  "bytes_sent": 34080,
  "connection_termination_details": null,
  "downstream_local_address": "10.88.1.14:15443",                                # This e-w pod IP, and inbound TCP port
  "downstream_remote_address": "10.138.0.101:19450",                             # Node that this e-w gateway is running on
  "duration": 460864,
  "method": null,
  "path": null,
  "protocol": null,
  "request_id": null,
  "requested_server_name": "outbound_.80_._.frontend.web-ui-team.solo-io.mesh", # SNI from incoming request
  "response_code": 0,
  "response_code_details": null,
  "response_flags": "-",
  "route_name": null,
  "start_time": "2023-03-14T18:01:05.349Z",
  "upstream_cluster": "outbound_.80_._.frontend.web-ui.svc.cluster.local",      # Envoy cluster that matched this request
  "upstream_host": "10.88.0.12:8080",                                           # Where am I going to? The endpoint of the frontend pod
  "upstream_local_address": "10.88.1.14:43984",                                 # This e-w pod IP, and outbound TCP port
  "upstream_service_time": null,
  "upstream_transport_failure_reason": null,
  "user_agent": null,
  "x_forwarded_for": null,
}
```
