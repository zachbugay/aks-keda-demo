#!/usr/bin/env bash
# Separately, each workload's OWN service account is federated with its OWN
# identity so the workload POD can reach its Service Bus at runtime. That
# federation is NOT used by KEDA for scaling.

set -euo pipefail
source "$(dirname "$0")/00-variables.sh"

export AKS_OIDC_ISSUER="$(az aks show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --query "oidcIssuerProfile.issuerUrl" -o tsv)"

fed() {
  # fed <identity> <name> <namespace> <serviceaccount>
  local identity="$1" name="$2" namespace="$3" sa="$4"
  if ! az identity federated-credential show \
      --name "$name" \
      --identity-name "$identity" \
      --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    az identity federated-credential create \
      --name "$name" \
      --identity-name "$identity" \
      --resource-group "$RESOURCE_GROUP" \
      --issuer "$AKS_OIDC_ISSUER" \
      --subject "system:serviceaccount:${namespace}:${sa}" \
      --audience api://AzureADTokenExchange -o none
    echo "Federated $identity  <-  system:serviceaccount:${namespace}:${sa}"
  else
    echo "Federated credential already exists: $name on $identity"
  fi
}

# KEDA operator Kubernetes Service Account with the identities KEDA may assume. 
# The SUbject is always system:serviceaccount:kube-system:keda-operator
fed "$KEDA_IDENTITY"       "keda-op-fed"          "$KEDA_SA_NAMESPACE" "$KEDA_SA_NAME"
fed "$WORKLOAD_A_IDENTITY" "keda-op-fed-for-a"    "$KEDA_SA_NAMESPACE" "$KEDA_SA_NAME"
fed "$WORKLOAD_B_IDENTITY" "keda-op-fed-for-b"    "$KEDA_SA_NAMESPACE" "$KEDA_SA_NAME"
fed "$WORKLOAD_C_IDENTITY" "keda-op-fed-for-c"    "$KEDA_SA_NAMESPACE" "$KEDA_SA_NAME"

# Each workload's own Kubernetes Service Account is federated with its own identity
fed "$WORKLOAD_A_IDENTITY" "workload-a-fed"       "$WORKLOAD_A_NAMESPACE" "$WORKLOAD_A_SA"
fed "$WORKLOAD_B_IDENTITY" "workload-b-fed"       "$WORKLOAD_B_NAMESPACE" "$WORKLOAD_B_SA"
fed "$WORKLOAD_C_IDENTITY" "workload-c-fed"       "$WORKLOAD_C_NAMESPACE" "$WORKLOAD_C_SA"

echo
echo "Done. KEDA's SA is federated with 4 identities; each workload SA with 1."
