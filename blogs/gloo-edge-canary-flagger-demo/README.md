# argocd + gloo edge + flagger canary demo

This repo takes configs from the [Flagger - Gloo Canary Deployments](https://docs.flagger.app/tutorials/gloo-progressive-delivery) documentation and demonstrates how to integrate these components with ArgoCD. Please review the Flagger documentation for more detail on progressive delivery using Flagger.

## Prerequisites
- ArgoCD installed on a Kubernetes cluster
- Gloo Edge installed on a Kubernetes cluster
- Flagger installed on a Kubernetes cluster

For more detail on installing ArgoCD, refer to the instructions [here](https://github.com/solo-io/gitops-library/tree/main/argocd/)

For more detail on installing Gloo Edge, refer to the ArgoCD or Helm deployments [here](https://github.com/solo-io/gitops-library/tree/main/gloo-edge/deploy)

For more detail on installing Flagger, refer to the ArgoCD or Helm deployments [here](https://github.com/solo-io/gitops-library/tree/main/flagger/deploy)

## Usage
If the prerequisites above are met, you can just deploy the base overlay argo app-of-app. This will deploy the podinfo application v6.0.0
```
kubectl apply -f https://raw.githubusercontent.com/ably77/canary-flagger-demo/main/base-overlay-aoa.yaml
```

Check the test namespace
```
% k get pods -n test
NAME                                  READY   STATUS    RESTARTS   AGE
flagger-loadtester-6cb5cdcd75-c5lm9   1/1     Running   0          3h49m
podinfo-primary-7db76b46bb-ls5xk      1/1     Running   0          119s
podinfo-primary-7db76b46bb-t2lqk      1/1     Running   0          119s
```

## Access the podinfo app
You can access the app at your gateway in your browser
```
glooctl proxy url
```

or using curl
```
curl $(glooctl proxy url)
{
  "hostname": "podinfo-primary-56b9d86997-sm7h8",
  "version": "6.0.0",
  "revision": "",
  "color": "#34577c",
  "logo": "https://raw.githubusercontent.com/stefanprodan/podinfo/gh-pages/cuddle_clap.gif",
  "message": "greetings from podinfo v6.0.0",
  "goos": "linux",
  "goarch": "arm64",
  "runtime": "go1.16.5",
  "num_goroutine": "10",
  "num_cpu": "8"
}
```

## Instantiate a status error
To instantiate an error, hit the `/status/<code>` endpoint of the podinfo app. We can use this to test our custom Prometheus `MetricTemplate` analysis which will halt a stage if the percentage of non-200 status codes goes above > 1% in a `1m` interval
```
% curl $(glooctl proxy url)/status/404
{
  "status": 404
}
```

## Progressive Delivery
In this example we are going to promote to podinfo v6.0.1 which is part of the dev-6.0.1 overlay
```
kubectl apply -f https://raw.githubusercontent.com/ably77/canary-flagger-demo/main/dev-6.0.1-aoa.yaml
```

## Watch flagger logs
```
kubectl -n gloo-system logs deployment/flagger -f | jq .msg
```

## Successful output
Below is the output of a successful progressive delivery. Note that at the beginning of the test, a few 500 errors were injected by hitting the `/status/500` endpoint in order to visualize the halting process. 
```
"New revision detected! Scaling up podinfo.test"
"canary deployment podinfo.test not ready: waiting for rollout to finish: 0 of 2 (readyThreshold 100%) updated replicas are available"
"canary deployment podinfo.test not ready: waiting for rollout to finish: 0 of 2 (readyThreshold 100%) updated replicas are available"
"Starting canary analysis for podinfo.test"
"Pre-rollout check acceptance-test passed"
"Advance podinfo.test canary weight 5"
"Halt advancement no values found for gloo metric request-success-rate probably podinfo.test is not receiving traffic: running query failed: no values found"
"Halt podinfo.test advancement podinfo-prometheus 8.57 > 1"
"Halt podinfo.test advancement podinfo-prometheus 3.61 > 1"
"Halt podinfo.test advancement podinfo-prometheus 2.28 > 1"
"Halt podinfo.test advancement podinfo-prometheus 1.68 > 1"
"Halt podinfo.test advancement podinfo-prometheus 1.14 > 1"
"Advance podinfo.test canary weight 10"
"Advance podinfo.test canary weight 15"
"Advance podinfo.test canary weight 20"
"Advance podinfo.test canary weight 25"
"Advance podinfo.test canary weight 30"
"Advance podinfo.test canary weight 35"
"Advance podinfo.test canary weight 40"
"Advance podinfo.test canary weight 45"
"Advance podinfo.test canary weight 50"
"Copying podinfo.test template spec to podinfo-primary.test"
"podinfo-primary.test not ready: waiting for rollout to finish: 1 old replicas are pending termination"
"HorizontalPodAutoscaler v2 podinfo-primary.test updated"
"Routing all traffic to primary"
"Promotion completed! Scaling down podinfo.test"
```

## Promote again
(optional) you can also promote again to podinfo v6.0.2 which is part of the dev-6.0.2 overlay
```
kubectl apply -f https://raw.githubusercontent.com/ably77/canary-flagger-demo/main/dev-6.0.2-aoa.yaml
```

## Troubleshooting
On initial deploy if you see the following error `"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"` in flagger logs, you may need to hit the `/status` endpoint with a non 200 so that the prometheus metric exists.
```
"New revision detected! Scaling up podinfo.test"
"canary deployment podinfo.test not ready: waiting for rollout to finish: 0 of 2 (readyThreshold 100%) updated replicas are available"
"canary deployment podinfo.test not ready: waiting for rollout to finish: 0 of 2 (readyThreshold 100%) updated replicas are available"
"Starting canary analysis for podinfo.test"
"Pre-rollout check acceptance-test passed"
"Advance podinfo.test canary weight 5"
"Halt advancement no values found for gloo metric request-success-rate probably podinfo.test is not receiving traffic: running query failed: no values found"
"Halt advancement no values found for gloo metric request-success-rate probably podinfo.test is not receiving traffic: running query failed: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Halt advancement no values found for custom metric: podinfo-prometheus: no values found"
"Rolling back podinfo.test failed checks threshold reached 10"
"Canary failed! Scaling down podinfo.test"
```