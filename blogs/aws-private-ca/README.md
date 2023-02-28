Script to set up the AWS Private Certificate Authority with one root cert and a subordinate cert lives here.
[Blog link](https://www.solo.io/blog/istio-aws-private-certificate-authority)

**Usage**

`./setup-AWS-PrivateCA.sh`

**Success Output Example**

```bash
-----------------------------------------------------------
ARN of Istio CA is arn:aws:acm-pca:[REGION]:[AWS_ACCOUNT]:certificate-authority/[ID_OF_CERT]
-----------------------------------------------------------
```
