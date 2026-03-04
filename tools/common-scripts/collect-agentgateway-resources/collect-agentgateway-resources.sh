#!/usr/bin/env bash
#
# collect-agentgateway-resources.sh
#
# Collects all custom resource objects for Enterprise AgentGateway,
# Kubernetes Gateway API, and related Solo.io CRDs from a cluster.
#
# Usage:
#   ./collect-agentgateway-resources.sh [--namespace <ns>] [--all-namespaces] [--output <dir>]
#
# Defaults to --all-namespaces. Output goes to a timestamped directory.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
API_GROUPS=(
  "gateway.networking.k8s.io"
  "agentgateway.dev"
  "enterpriseagentgateway.solo.io"
  "ratelimit.solo.io"
  "extauth.solo.io"
)

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
NAMESPACE_FLAG=(--all-namespaces)
OUTPUT_DIR=""

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace|-n)
      NAMESPACE_FLAG=(--namespace "$2"); shift 2 ;;
    --all-namespaces|-A)
      NAMESPACE_FLAG=(--all-namespaces); shift ;;
    --output|-o)
      OUTPUT_DIR="$2"; shift 2 ;;
    --help|-h)
      head -12 "$0" | tail -8; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$OUTPUT_DIR" ]]; then
  OUTPUT_DIR="agentgateway-dump-${TIMESTAMP}"
fi
mkdir -p "$OUTPUT_DIR"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log() { echo "[$(date +%H:%M:%S)] $*"; }

# ---------------------------------------------------------------------------
# 1. Cluster info
# ---------------------------------------------------------------------------
log "Collecting cluster info..."
{
  echo "=== kubectl version ==="
  kubectl version --output=yaml 2>/dev/null || kubectl version 2>/dev/null || true
  echo ""
  echo "=== current context ==="
  kubectl config current-context 2>/dev/null || true
  echo ""
  echo "=== cluster-info ==="
  kubectl cluster-info 2>/dev/null || true
} > "${OUTPUT_DIR}/cluster-info.txt"

# ---------------------------------------------------------------------------
# 2. Discover CRDs for each API group
# ---------------------------------------------------------------------------
log "Discovering API resources for target groups..."
ALL_RESOURCES=()

for group in "${API_GROUPS[@]}"; do
  log "  Checking group: ${group}"

  # Get resource names from api-resources (skip header)
  resources=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && resources+=("$line")
  done <<EOF
$(kubectl api-resources --api-group="${group}" --no-headers 2>/dev/null | awk '{print $1}')
EOF

  if [[ ${#resources[@]} -eq 0 ]]; then
    log "    (no resources found — CRDs may not be installed)"
    continue
  fi

  for res in "${resources[@]}"; do
    [[ -z "$res" ]] && continue
    ALL_RESOURCES+=("${res}.${group}")
    log "    Found: ${res}.${group}"
  done
done

if [[ ${#ALL_RESOURCES[@]} -eq 0 ]]; then
  log "ERROR: No matching API resources found in the cluster."
  log "Make sure AgentGateway / Gateway API CRDs are installed."
  exit 1
fi

# ---------------------------------------------------------------------------
# 3. Save CRD definitions
# ---------------------------------------------------------------------------
log "Collecting CRD definitions..."
CRD_DIR="${OUTPUT_DIR}/crds"
mkdir -p "$CRD_DIR"

for fqn in "${ALL_RESOURCES[@]}"; do
  crd_name="${fqn}"
  kubectl get crd "${crd_name}" -o yaml > "${CRD_DIR}/${crd_name}.yaml" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# 4. Dump all objects for each resource type
# ---------------------------------------------------------------------------
log "Collecting resource objects..."
OBJECTS_DIR="${OUTPUT_DIR}/objects"
mkdir -p "$OBJECTS_DIR"

SUMMARY_FILE="${OUTPUT_DIR}/summary.txt"
echo "AgentGateway Resource Dump — ${TIMESTAMP}" > "$SUMMARY_FILE"
echo "============================================" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

total_objects=0

for fqn in "${ALL_RESOURCES[@]}"; do
  res_short="${fqn%%.*}"
  group="${fqn#*.}"

  # Get object count first
  count=$(kubectl get "${fqn}" "${NAMESPACE_FLAG[@]}" --no-headers 2>/dev/null | wc -l | tr -d ' ')

  if [[ "$count" -eq 0 ]]; then
    log "  ${fqn}: 0 objects"
    echo "${fqn}: 0 objects" >> "$SUMMARY_FILE"
    continue
  fi

  log "  ${fqn}: ${count} objects"
  echo "${fqn}: ${count} objects" >> "$SUMMARY_FILE"
  total_objects=$((total_objects + count))

  # Save list view
  kubectl get "${fqn}" "${NAMESPACE_FLAG[@]}" -o wide \
    > "${OBJECTS_DIR}/${res_short}.${group}.list.txt" 2>/dev/null || true

  # Save full YAML
  kubectl get "${fqn}" "${NAMESPACE_FLAG[@]}" -o yaml \
    > "${OBJECTS_DIR}/${res_short}.${group}.yaml" 2>/dev/null || true
done

# ---------------------------------------------------------------------------
# 5. Collect related workloads & services (agentgateway namespaces)
# ---------------------------------------------------------------------------
log "Collecting related workloads..."
WORKLOADS_DIR="${OUTPUT_DIR}/workloads"
mkdir -p "$WORKLOADS_DIR"

# Auto-detect namespaces that have agentgateway resources
AG_NAMESPACES=$(kubectl get deployments --all-namespaces --no-headers 2>/dev/null \
  | grep -iE 'agentgateway|agent-gateway' \
  | awk '{print $1}' \
  | sort -u || true)

for ns in $AG_NAMESPACES; do
  log "  Namespace: ${ns}"
  ns_dir="${WORKLOADS_DIR}/${ns}"
  mkdir -p "$ns_dir"

  kubectl get pods -n "$ns" -o wide > "${ns_dir}/pods.txt" 2>/dev/null || true
  kubectl get deployments -n "$ns" -o yaml > "${ns_dir}/deployments.yaml" 2>/dev/null || true
  kubectl get services -n "$ns" -o yaml > "${ns_dir}/services.yaml" 2>/dev/null || true
  kubectl get configmaps -n "$ns" -o yaml > "${ns_dir}/configmaps.yaml" 2>/dev/null || true
  # List secret names/types only — never dump secret data
  kubectl get secrets -n "$ns" -o custom-columns=NAME:.metadata.name,TYPE:.type,AGE:.metadata.creationTimestamp \
    > "${ns_dir}/secrets-list.txt" 2>/dev/null || true

  # Pod logs (last 200 lines each, non-blocking)
  for pod in $(kubectl get pods -n "$ns" --no-headers 2>/dev/null | awk '{print $1}'); do
    kubectl logs -n "$ns" "$pod" --all-containers --tail=200 \
      > "${ns_dir}/logs-${pod}.txt" 2>/dev/null || true
  done
done

# ---------------------------------------------------------------------------
# 6. Collect Helm release info
# ---------------------------------------------------------------------------
if command -v helm &>/dev/null; then
  log "Collecting Helm release info..."
  HELM_DIR="${OUTPUT_DIR}/helm"
  mkdir -p "$HELM_DIR"

  # List all releases, filter for agentgateway-related ones
  while IFS=$'\t' read -r name namespace chart status revision; do
    [[ -z "$name" ]] && continue
    log "  Found release: ${name} (namespace: ${namespace}, chart: ${chart})"

    # User-supplied values (overrides only)
    helm get values "$name" -n "$namespace" \
      > "${HELM_DIR}/${name}.values.yaml" 2>/dev/null || true

    # All computed values (user + defaults)
    helm get values "$name" -n "$namespace" --all \
      > "${HELM_DIR}/${name}.values-all.yaml" 2>/dev/null || true

    # Release metadata
    {
      echo "release: ${name}"
      echo "namespace: ${namespace}"
      echo "chart: ${chart}"
      echo "status: ${status}"
      echo "revision: ${revision}"
    } > "${HELM_DIR}/${name}.info.txt"

  done < <(helm list --all-namespaces --output table 2>/dev/null \
    | awk 'NR>1' \
    | grep -iE 'agentgateway|agent-gateway' \
    | awk '{print $1"\t"$2"\t"$9"\t"$7"\t"$3}' \
    || true)

  if [ -z "$(ls -A "$HELM_DIR" 2>/dev/null)" ]; then
    log "  No agentgateway Helm releases found"
    rmdir "$HELM_DIR" 2>/dev/null || true
  fi
else
  log "Helm not found — skipping Helm values collection"
fi

# ---------------------------------------------------------------------------
# 7. Final summary
# ---------------------------------------------------------------------------
{
  echo ""
  echo "Total objects collected: ${total_objects}"
  echo "AgentGateway namespaces: ${AG_NAMESPACES:-none detected}"
} >> "$SUMMARY_FILE"

log "Done. ${total_objects} resource objects collected."
log ""
log "Directory structure:"
find "$OUTPUT_DIR" -type f | sort | sed "s|^${OUTPUT_DIR}/|  |"

# ---------------------------------------------------------------------------
# 7. Package into archive
# ---------------------------------------------------------------------------
ARCHIVE="${OUTPUT_DIR}.tar.gz"
log "Creating archive: ${ARCHIVE}"
tar czf "$ARCHIVE" "$OUTPUT_DIR"
log "Archive created: ${ARCHIVE} ($(du -h "$ARCHIVE" | awk '{print $1}'))"
log "You can now share this single file."
