# Deploying 3 EKS clusters using eksctl

[eksctl](https://eksctl.io/) is a useful tool in creating EKS clusters. This guide will show you how to create 3 working clusters to use for this demo.


* Deploy all three clusters using eksctl

```sh
eksctl create cluster -f infra/eks/mgmt.yaml &
eksctl create cluster -f infra/eks/cluster1.yaml &

wait
```

* Update the kubernetes context names

```sh
kubectl config rename-context <user>@gloo-cluster1.us-west-2.eksctl.io cluster1
kubectl config rename-context <user>@gloo-mgmt.us-west-2.eksctl.io mgmt
```


## Install AWS [Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)

* Create IAM Policy to allow service accounts to create aws load balancers

```sh
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

* Enable OIDC provider for service accounts

```sh
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=gloo-mgmt --approve
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=gloo-cluster1 --approve
```

* Create service accounts for each cluster
```sh
AWS_ACCOUNT_ID=[111111...]
eksctl create iamserviceaccount \
  --cluster=gloo-mgmt \
  --region us-west-2 \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
  --override-existing-serviceaccounts \
  --approve

eksctl create iamserviceaccount \
  --cluster=gloo-cluster1 \
  --region us-west-2 \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
  --override-existing-serviceaccounts \
  --approve
```

* Install load balancer controller to each cluster

```sh
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --kube-context mgmt \
  --set clusterName=gloo-mgmt \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --kube-context cluster1 \
  --set clusterName=gloo-cluster1 \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 
```


## Delete clusters

* Clean up clusters

```sh
# clean up load balancers
kubectl delete service --all -n gloo-mesh --context mgmt
kubectl delete service --all -n keycloak --context cluster1
kubectl delete service --all -n istio-gateways --context cluster1

# delete pod disruption budget which prevent deletion of the nodes
kubectl delete pdb -A --all --context cluster1
kubectl delete pdb -A --all --context mgmt
```


* Delete clusters

```sh
eksctl delete cluster -f eks/mgmt.yaml &
eksctl delete cluster -f eks/cluster1.yaml & 

wait
```