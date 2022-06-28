# GKE Cluster Creation

```
GCP_PROJECT=<project>
GCP_ZONE=us-east4-a


gcloud container clusters create "gloo-gateway" \
  --project="$GCP_PROJECT" \
  --cluster-version="1.22.8-gke.202" \
  --zone="$GCP_ZONE" \
  --machine-type="e2-standard-4" \
  --num-nodes="2" \
  --no-enable-legacy-authorization




```