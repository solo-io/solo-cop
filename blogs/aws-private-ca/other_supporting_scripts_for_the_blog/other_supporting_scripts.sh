#########################################################################################################
#########################################################################################################
# Install Cert Manager

CERT_MANAGER_VERSION=v1.11.0
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version ${CERT_MANAGER_VERSION} \
  --set installCRDs=true \
  --wait;

# verify
kubectl -n cert-manager rollout status deploy/cert-manager;
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector;
kubectl -n cert-manager rollout status deploy/cert-manager-webhook;



#########################################################################################################
#########################################################################################################
# Create IAM Policy and Role

cat <<EOF > AWSPCAIssuerPolicy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "awspcaissuer",
      "Action": [
        "acm-pca:DescribeCertificateAuthority",
        "acm-pca:GetCertificate",
        "acm-pca:IssueCertificate"
      ],
      "Effect": "Allow",
      "Resource": [
        "${ISTIO_CA_ARN}"
        ]
    }
  ]
}
EOF

POLICY_ARN=$(aws iam create-policy \
    --policy-name AWSPCAIssuerPolicy \
    --policy-document file://AWSPCAIssuerPolicy.json \
    --output json | jq -r '.Policy.Arn')

echo "POLICY_ARN = ${POLICY_ARN}"


#########################################################################################################
#########################################################################################################
# Create IAM Role with IAM OIDC Provider

# Please edit the cluster name below
export CURRENT_CLUSTER=<YOUR_CLUSTER_NAME>

# Enable the IAM OIDC Provider for the cluster
eksctl utils associate-iam-oidc-provider \
    --cluster=${CURRENT_CLUSTER} \
    --approve;

# Create IAM role bound to a service account
eksctl create iamserviceaccount --cluster=${CURRENT_CLUSTER} \
    --namespace=${PCA_NAMESPACE} \
    --attach-policy-arn=${POLICY_ARN} \
    --override-existing-serviceaccounts \
    --name="aws-pca-issuer" \
    --role-name "ServiceAccountRolePrivateCA-${CURRENT_CLUSTER}" \
    --approve;


#########################################################################################################
#########################################################################################################
# Install aws-privateca-issuer plugin and use the ServiceAccount: aws-pca-issuer

export PCA_NAMESPACE=cert-manager

# Check latest version https://github.com/cert-manager/aws-privateca-issuer/releases
export AWSPCA_ISSUER_TAG=v1.2.2

# Install AWS Private CA Issuer Plugin 
# https://github.com/cert-manager/aws-privateca-issuer/#setup
helm repo add awspca https://cert-manager.github.io/aws-privateca-issuer
helm repo update
helm upgrade --install aws-pca-issuer awspca/aws-privateca-issuer \
    --namespace ${PCA_NAMESPACE} \
    --set image.tag=${AWSPCA_ISSUER_TAG} \
    --set serviceAccount.create=false \
    --set serviceAccount.name="aws-pca-issuer" \
    --wait;

# Verify deployment status
kubectl -n ${PCA_NAMESPACE} \
    rollout status deploy/aws-pca-issuer-aws-privateca-issuer;


#########################################################################################################
#########################################################################################################
# Create Issuer

cat << EOF | kubectl apply -f -
apiVersion: awspca.cert-manager.io/v1beta1
kind: AWSPCAIssuer
metadata:
 name: aws-pca-issuer-istio
 namespace: istio-system
spec:
  arn: ${ISTIO_CA_ARN}
  region: ${CA_REGION}
EOF


#########################################################################################################
#########################################################################################################
# Create CA Certificate for Istio (cacerts secret)

# Issue CA certificate from AWS PCA with the help of cert-manager and aws-pca-issuer plugin
cat << EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: istio-ca
  namespace: istio-system
spec:
  isCA: true
  duration: 720h #30d
 renewBefore: 360h #15d
  secretName: cacerts
  commonName: istio-ca
  dnsNames:
    - "*.istiod-${ISTIO_REVISION}" # Istiod identity
  subject:
    organizations:
    - cluster.local
    - cert-manager
  issuerRef:
# ---------------- Issuer for Istio CA ---------------------------
    group: awspca.cert-manager.io
    kind: AWSPCAIssuer
    name: aws-pca-issuer-istio
# ---------------- Issuer for Istio CA ---------------------------
EOF


#########################################################################################################
#########################################################################################################
# Just before "Debug suggestion"
istioctl pc secret \
    -n [NAMESPACE] deploy/DEPLOYMENT_NAME -o json | \
    jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | \
    base64 -d | \
    openssl x509 -noout -text
