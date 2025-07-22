Contains miscellaneous scripts used with Gloo Mesh

### setup-AWS-PrivateCA-Gloo-Mesh-and-Istio.sh
Sets up the following Certificate Authorities(CA) in AWS Private CA

- A Root CA
- 2 Subordinate CAs

The Subordinate CAs are signed by the Root CA. One of the Subordinate CA is meant for setting up custom CA for Gloo Mesh. Another Subordinate CA isused to setup the custom CA for Istio.

![AWS PCA](../images/cert-manager-AWS-Private-CA-integration-for-custom-CA.png)

Related article: [Cert Manager and AWS Private CA integration](https://soloio.slab.com/posts/cert-manager-and-aws-private-ca-integration-gruzsn2n)
