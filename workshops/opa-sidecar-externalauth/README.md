# OPA ExternalAuth with sidecar in Gloo Platform

Let’s try out OPA (Open Policy Agent) sidecar with ExternalAuth in Gloo Platform. To use this feature, you will need a valid Gloo Platform license or a trial key. If you don’t have one, you can [(request one here)](https://www.solo.io/free-trial/).

## Prerequisites
- One (1) Kubernetes cluster with Gloo Mesh or Gloo Gateway installed and configured. See [Gloo Mesh Getting Started](https://docs.solo.io/gloo-mesh/latest/getting_started/) for more details.
- Install the [Open Policy Agent CLI](https://www.openpolicyagent.org/docs/latest/#running-opa). We will use this to build our rego bundle.
- Read/write access to a public GCS or similar cloud storage bucket.
- This workshop has been tested with Gloo Platform 2.4.4.
- This workshop assumes the environment is clean. If you have previously installed Gloo Mesh, please uninstall it and any custom resources you have configured before proceeding.

## Configuring OPA

OPA server in sidecar mode is configured directly using the OPA configuration file API: https://www.openpolicyagent.org/docs/latest/configuration/. This configuration file allows you to load bundles, specify services, control logging and tracing for the sidecar, and more. This config file is loaded into a Kubernetes ConfigMap by the Gloo Platform helm chart and is version-tracked so that the deployment is restarted automatically when the underlying config file is redeployed with helm. For that reason, it’s important to use GitOps as a best practice to manage your cluster in production. Today, we will simply specify our configuration file on the command line and install it with Helm. 

To use OPA server in sidecar mode, Rego policies must be loaded with a bundle from an HTTP service. For this workshop, we’re going to use a simple Rego policy that helps us control access to the `httpbin` service using ExternalAuth. Let’s imagine a fictional scenario where we want to control access to some httpbin endpoints: we’d like to disallow users from hitting the `/bytes` endpoint as it allows users to request arbitrarily large payloads, which can be expensive if we’re paying for egress. We want users to be able to GET or POST the other endpoints. Here’s the policy we will use:

```rego
package httpbin

import input.http_request

default allowed = false

# set allowed to true if there is no error message
allowed {
	not body
}

# return result and error message
allow["allowed"] = allowed
allow["body"] = body

# the main logic, including setting error messages for each rule
body = "HTTP verb is not allowed" {
	not http_verb_allowed
}

else = "Path is not allowed" {
	not path_allowed
}

http_verb_allowed {
	{"GET", "POST"}[_] == http_request.method
}

# do not allow access to the status endpoint
path_allowed {
	not startswith(http_request.path, "/bytes")
}
```

Create a directory on your machine for this project, and add the above rego policy in a subdirectory called `rego`. Next, we need a `.manifest` file to build the bundle. Add the following into `.manifest` alongside the rego file:

```json
{
    "roots": ["httpbin"]
}
```

This file will instruct OPA that we have a package that will own the `httpbin` name. Build your bundle by running `opa build -b .` in the `rego` directory. To do this, you'll need to install the OPA command-line utility. You can find instructions in the OPA docs: https://www.openpolicyagent.org/docs/latest/#running-opa.

Next, we need to upload this bundle to an HTTP service. There are lots of different options for this service – you can use a local NGINX server, a cloud storage service, and other options. We will use a GCP bucket today.

You can copy the bundle to GCS with the following command:

```shell
gsutil cp bundle.tar.gz gs://${YOUR_BUCKET_URL}
```

Finally, in our root directory for this tutorial, let’s create an OPA config file to reference this bundle server and bundle. We will add this file to our helm install. Add the following into `config.yaml`:

```yaml
services:
  gcs:
    url: https://storage.googleapis.com/storage/v1/b/${YOUR_BUCKET_NAME}/o
bundles:
  httpbin:
    service: gcs
      resource: 'httpbin.tar.gz?alt=media'
```

Now, we can install Gloo Platform with ExternalAuth enabled and the OPA sidecar configured. This is done with the Gloo Platform helm chart. You can set options and helm values as you would like and then include the following snippet in your values.yaml file:

```yaml
extAuthService:
  enabled: true
  extAuth:
    image:
      registry: gcr.io/gloo-mesh
      repository: ext-auth-service
      tag: v0.51.0
    opaServer:
      enabled: true
```

Let’s install this with helm, setting the `extAuthService.extAuth.opaServer.configYaml` value to our config file:

```bash
helm install gloo-platform gloo-platform/gloo-platform \
   --namespace gloo-mesh \
   --values values.yaml
  --set-file extAuthService.extAuth.opaServer.config=${OUR_DIRECTORY}/config.yaml"
```

Verify that the installation has been successful and that there are two containers running in the ext-auth-service pod in the `gloo-mesh-addons` namespace:

```
kubectl get pods -n gloo-mesh-addons
```

Now, let's finally install the httpbin sample application so we can control traffic to its endpoints. 

```
kubectl create ns httpbin && kubectl -n httpbin apply -f https://raw.githubusercontent.com/solo-io/gloo-mesh-use-cases/main/policy-demo/httpbin.yaml
```

Verify that the httpbin app is running by running `kubectl -n httpbin get pods -l app=httpbin` and verify that the `httpbin` application is `READY`.

Let’s create some resources to allow traffic to httpbin. Save the yaml below into a file in your project directory and apply it with `kubectl apply -f <your-file>.yaml`.

```yaml
apiVersion: admin.gloo.solo.io/v2
kind: Workspace
metadata:
  name: global
  namespace: gloo-mesh
spec:
  workloadClusters:
  - name: '*'
    namespaces:
    - name: '*'
---
apiVersion: admin.gloo.solo.io/v2
kind: WorkspaceSettings
metadata:
  name: global-wss
  namespace: gloo-mesh
spec:
  options:
    eastWestGateways:
    - selector:
      labels:
        istio: eastwestgateway
---
apiVersion: admin.gloo.solo.io/v2
kind: ExtAuthServer
metadata:
  name: default-server
  namespace: gloo-mesh-addons
spec:
  destinationServer:
    port:
      number: 8083
    ref:
      cluster: ${CLUSTER_NAME}
      name: ext-auth-service
      namespace: gloo-mesh-addons
---
apiVersion: networking.gloo.solo.io/v2
kind: RouteTable
metadata:
  name: www-example-com
  namespace: httpbin
spec:
  hosts:
    - "*"
  http:
    - name: httpbin
      matchers:
      - headers:
        - name: X-httpbin
      labels:
        route: httpbin
      forwardTo:
        destinations:
          - ref:
              name: httpbin
              namespace: httpbin
            port:
              number: 8000   
  virtualGateways:
  - name: istio-ingressgateway
    namespace: httpbin
---
apiVersion: networking.gloo.solo.io/v2
kind: VirtualGateway
metadata:
  name: istio-ingressgateway
  namespace: httpbin
spec:
  listeners:
  - http: {}
    port:
      number: 80
  workloads:
  - selector:
      labels:
        istio: ingressgateway
```

We created a simple `Workspace`, `WorkspaceSettings` object, an `ExtAuthServer` resource, and a `RouteTable` with an accompanying `VirtualGateway`. This route table and virtual gateway will send all traffic with the `X-httpbin` header to the httpbin service. Curl it through the ingress gateway IP to validate that we can send requests to the `bytes/200` and `status/200` endpoints before we configure the external auth server to use our rego policy. To learn more about these resources, check out the solo.io Gloo Gateway docs: https://docs.solo.io/gloo-gateway/latest/concepts/.

Now that we’ve verified routing is working, let’s apply an ExtAuthPolicy to configure ExternalAuth to use our rego policy. Save the yaml below into a file in your project directory and apply it with `kubectl apply -f <your-file>.yaml`.

```yaml
apiVersion: security.policy.gloo.solo.io/v2
kind: ExtAuthPolicy
metadata:
  name: opa-server-auth
  namespace: httpbin
spec:
  applyToRoutes:
  - route:
      labels:
        route: httpbin
  config:
    glooAuth:
      configs:
      - opaServerAuth:
          package: httpbin
          ruleName: allow/allowed
    server:
      cluster: ${CLUSTER_NAME}
      name: default-server
      namespace: gloo-mesh-addons
```

This ExtAuthPolicy uses the `httpbin` rego package and the `allow/allowed` boolean value to determine whether a request is authorized or not. Try curling the ingress gateway IP again for the `status/200` endpoint, and verify that you can `GET` the results:

```shell
curl -vik http://${INGRESS_GATEWAY_IP}:80/status/200  -H "X-httpbin: true"
```

Now try curling the `bytes/200` endpoint: 

```shell
curl -vik http://${INGRESS_GATEWAY_IP}:80/bytes/200  -H "X-httpbin: true"
```

See how you got a 200 from the first request, but a 403 from the second? Our ExtAuthPolicy is working!

## Conclusion
In this workshop, we have demonstrated creating a Rego policy to 
