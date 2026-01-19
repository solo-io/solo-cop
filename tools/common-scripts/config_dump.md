# Function to get the envoy admin config dump

Save the function to a file and source it in your shell.

```bash
get_envoy_admin_config_dump() {
  TIMESTAMP=$(date +%Y%m%d%H%M%S)
  kubectl -n "${1}" port-forward "deploy/${2}" "${3}" & PID=$!
  echo "[DEBUG] Wait for the port-forward to be established"
  sleep 3
  curl -s "http://localhost:${ENVOY_ADMIN_PORT}/config_dump?include_eds" > "config-dump-${1}-${TIMESTAMP}.json"
  kill $PID
  echo; echo "[INFO] Envoy admin config dump for ${1} saved to config-dump-${1}-${TIMESTAMP}.json"; echo;
}
```

## Usage

```bash
get_envoy_admin_config_dump <namespace> <deployment_name> <envoy_admin_port>
```

### Example for KGateway

Admin port is `19000`

```bash
NAMESPACE=kgateway-system
DEPLOYMENT_NAME=http
ENVOY_ADMIN_PORT=19000
get_envoy_admin_config_dump ${NAMESPACE} ${DEPLOYMENT_NAME} ${ENVOY_ADMIN_PORT}
```

### Example for Istio Proxy (sidecars, waypoints etc.)

Admin port is `15000`

```bash
NAMESPACE=istio-ingress
DEPLOYMENT_NAME=istio-ingressgateway
ENVOY_ADMIN_PORT=15000
get_envoy_admin_config_dump ${NAMESPACE} ${DEPLOYMENT_NAME} ${ENVOY_ADMIN_PORT}
```
