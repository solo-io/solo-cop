![k9s-three-cluster](https://github.com/solo-io/solo-cop/blob/main/tools/cli-productivity/k9s-gloo-mesh.png?raw=true)

Tools:
- https://k9scli.io/ s a terminal based UI to interact with your Kubernetes clusters. 
- https://github.com/sbstp/kubie offerscontext switching, namespace switching and prompt modification in a way that makes each shell independent from others. It also has support for split configuration files, meaning it can load Kubernetes contexts from multiple files. 

Get all Gloo Mesh resources:
```
kubectl get solo-io -A
```
and Istio resources:
```
kubectl get istio-io -A
```

See Istio information:
```
alias istio='kubectl get deploy,pods,svc -A | grep istio'
```

Logs for gloo mesh agent and mgmt server:
```
alias agentlogs='kubectl logs -l app=gloo-mesh-agent -n gloo-mesh'
alias mgmtlogs='kubectl logs -f -l app=gloo-mesh-mgmt-server -n gloo-mesh`
```

Gather the mgmt server snapshot:
```
alias snapshots='rm -rf ./snapshots.zip && curl -s https://gist.githubusercontent.com/rvennam/07a774e2b72da558eabdd70732073373/raw/bb17764db93745f2eb01c681dcb7ff3f3d2760cd/snapshots.sh | bash'
```
