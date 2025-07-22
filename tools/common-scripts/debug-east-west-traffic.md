# east-west connectivity debugging

### Get endpoints for a VirtualDestination with `pc endpoints`

```bash
istioctl pc endpoints \
  -n istio-gateways deploy/istio-ingressgateway | \
  grep productpage.global | \
  cut -f1 -d ' '
```

Output:
```
# local endpoint
10.128.3.157:9080
# remote e-w gateways
107.21.153.246:15443
3.226.201.88:15443
35.160.246.82:15443
35.167.16.0:15443
52.54.196.35:15443
```

### Get endpoints for a VirtualDestination with `envoy-stats`

```bash
istioctl x envoy-stats \
  -n istio-gateways "deploy/istio-ingressgateway" \
  --type clusters | \
  grep "productpage.global" | \
  grep ":hostname"
```

Output
```bash
outbound|9080||productpage.global::52.54.196.35:15443::hostname::a6c51b0abaaa94cc7a810184af9d7e47-1717122493.us-east-1.elb.amazonaws.com
outbound|9080||productpage.global::107.21.153.246:15443::hostname::a6c51b0abaaa94cc7a810184af9d7e47-1717122493.us-east-1.elb.amazonaws.com
outbound|9080||productpage.global::3.226.201.88:15443::hostname::a6c51b0abaaa94cc7a810184af9d7e47-1717122493.us-east-1.elb.amazonaws.com
outbound|9080||productpage.global::10.128.3.157:9080::hostname::10.128.3.157
outbound|9080||productpage.global::35.167.16.0:15443::hostname::a3ba05592ec804e2ab579feb1138541c-339508063.us-west-2.elb.amazonaws.com
outbound|9080||productpage.global::35.160.246.82:15443::hostname::a3ba05592ec804e2ab579feb1138541c-339508063.us-west-2.elb.amazonaws.com
```

# Test with netcat

```bash
### from Ingress gateway
kubectl exec -it \
  -n istio-gateways deploy/istio-ingressgateway -- \
  sh -c \
  'nc -zv 3.226.201.88 15443'
```

Success response:
`Connection to 3.226.201.88 15443 port [tcp/*] succeeded!`

### Same command from `istio-proxy` container of an app running on the mesh

```bash
kubectl exec -it \
    -n bookinfo-frontends "deploy/productpage-v1" \
    -c istio-proxy -- \
    sh -c \
    'nc -zv 3.226.201.88 15443'
```

## Check generated WorkloadEntry objects

Example:

```bash
# drew-ocp-cluster2 (where my north south traffic enters)
kubectl -n bookinfo-frontends get workloadentry -l "gloo.solo.io/parent_name"="productpage"
NAME                                                              AGE   ADDRESS
vd-productpage-global-frontend--3c9ae37c7c601aa8f4d8b0c3073b9ee   32d   a3ba05592ec804e2ab579feb1138541c-339508063.us-west-2.elb.amazonaws.com
vd-productpage-global-frontend--d451fc4f3cf6c9608c5504bd45e573a   33d   a6c51b0abaaa94cc7a810184af9d7e47-1717122493.us-east-1.elb.amazonaws.com
```

```bash
# remote cluster 1
kubectl --context ext-apps-test-cluster -n istio-gateways get svc/istio-eastwestgateway
NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                           AGE
istio-eastwestgateway   LoadBalancer   10.100.251.198   a3ba05592ec804e2ab579feb1138541c-339508063.us-west-2.elb.amazonaws.com   15021:32324/TCP,15443:32535/TCP   40d
```

```bash
# remote cluster 2
kubectl --context drew-ocp-cluster3 -n istio-gateways get svc/istio-eastwestgateway
NAME                    TYPE           CLUSTER-IP     EXTERNAL-IP                                                               PORT(S)                           AGE
istio-eastwestgateway   LoadBalancer   172.30.154.0   a6c51b0abaaa94cc7a810184af9d7e47-1717122493.us-east-1.elb.amazonaws.com   15021:30338/TCP,15443:31551/TCP   76d
```

```bash
kubectl -n bookinfo-frontends get workloadentry -l "gloo.solo.io/parent_name"="productpage" -o yaml | grep -A 7 'spec:'
```

```yaml
  spec:
    address: a3ba05592ec804e2ab579feb1138541c-339508063.us-west-2.elb.amazonaws.com
    labels:
      app: productpage
      security.istio.io/tlsMode: istio
    locality: us-west-2
    ports:
      http-9080: 15443
--
  spec:
    address: a6c51b0abaaa94cc7a810184af9d7e47-1717122493.us-east-1.elb.amazonaws.com
    labels:
      app: productpage
      security.istio.io/tlsMode: istio
    locality: us-east-1
    ports:
      http-9080: 15443
```
