#!/usr/bin/env bash

# Ref: https://learn.microsoft.com/en-us/azure/aks/keda-deploy-add-on-cli
set -euo pipefail
source "$(dirname "$0")/00-variables.sh"

# Make sure the add-on preview extension/feature is available.
az extension add --name aks-preview 2>/dev/null || az extension update --name aks-preview

# Enable KEDA, the OIDC issuer, and the workload identity webhook on the cluster.
az aks update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --enable-keda \
  --enable-oidc-issuer \
  --enable-workload-identity

# Capture the cluster OIDC issuer URL
export AKS_OIDC_ISSUER="$(az aks show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CLUSTER_NAME" \
  --query "oidcIssuerProfile.issuerUrl" -o tsv)"

echo "OIDC issuer: $AKS_OIDC_ISSUER"

# Verify the add-on is healthy and the operator runs as kube-system/keda-operator.
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
kubectl get pods -n "$KEDA_SA_NAMESPACE" -l app=keda-operator
