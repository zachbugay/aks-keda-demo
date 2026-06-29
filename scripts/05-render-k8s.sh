#!/usr/bin/env bash
# Render k8s manifests from templates by substituting live values from Azure.
#
# Reads templates from ./k8s/templates/, substitutes placeholders using the
# identity clientIds fetched from Azure and the Service Bus namespace names
# from 00-variables.sh, then writes the ready-to-apply manifests to ./k8s/.
#
# Placeholders substituted:
#   <WORKLOAD_A_CLIENT_ID>  — clientId of id-workload-a
#   <WORKLOAD_B_CLIENT_ID>  — clientId of id-workload-b
#   <WORKLOAD_C_CLIENT_ID>  — clientId of id-workload-c
#   <SB_A_NAMESPACE>        — Service Bus namespace name for workload A
#   <SB_B_NAMESPACE>        — Service Bus namespace name for workload B
#   <SB_C_NAMESPACE>        — Service Bus namespace name for workload C
set -euo pipefail
source "$(dirname "$0")/00-variables.sh"

TEMPLATE_DIR="k8s/templates"
OUTPUT_DIR="k8s"

echo "Fetching identity clientIds from Azure..."
WORKLOAD_A_CLIENT_ID="$(az identity show --name "$WORKLOAD_A_IDENTITY" --resource-group "$RESOURCE_GROUP" --query clientId -o tsv)"
WORKLOAD_B_CLIENT_ID="$(az identity show --name "$WORKLOAD_B_IDENTITY" --resource-group "$RESOURCE_GROUP" --query clientId -o tsv)"
WORKLOAD_C_CLIENT_ID="$(az identity show --name "$WORKLOAD_C_IDENTITY" --resource-group "$RESOURCE_GROUP" --query clientId -o tsv)"

echo "Rendering manifests..."
for template in service-accounts.yaml trigger-authentications.yaml deployments.yaml scaledobjects.yaml; do
  sed \
    -e "s|<WORKLOAD_A_CLIENT_ID>|${WORKLOAD_A_CLIENT_ID}|g" \
    -e "s|<WORKLOAD_B_CLIENT_ID>|${WORKLOAD_B_CLIENT_ID}|g" \
    -e "s|<WORKLOAD_C_CLIENT_ID>|${WORKLOAD_C_CLIENT_ID}|g" \
    -e "s|<SB_A_NAMESPACE>|${SB_A_NAMESPACE}|g" \
    -e "s|<SB_B_NAMESPACE>|${SB_B_NAMESPACE}|g" \
    -e "s|<SB_C_NAMESPACE>|${SB_C_NAMESPACE}|g" \
    "${TEMPLATE_DIR}/${template}" > "${OUTPUT_DIR}/${template}"
  echo "  Rendered ${template}"
done

