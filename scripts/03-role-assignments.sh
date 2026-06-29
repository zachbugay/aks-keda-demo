#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/00-variables.sh"

# principalId (object id) of a user-assigned identity.
principal_id() {
  az identity show --name "$1" --resource-group "$RESOURCE_GROUP" --query principalId -o tsv
}

# resource id of a Service Bus namespace.
sb_scope() {
  az servicebus namespace show --name "$1" --resource-group "$RESOURCE_GROUP" --query id -o tsv
}

# create a role assignment only if it does not already exist.
assign_role() {
  local assignee="$1" role="$2" scope="$3" principal_type="${4:-ServicePrincipal}"
  local existing
  existing=$(az role assignment list \
    --assignee "$assignee" \
    --role "$role" \
    --scope "$scope" \
    --query "[0].id" -o tsv 2>/dev/null)
  if [ -z "$existing" ]; then
    az role assignment create \
      --assignee-object-id "$assignee" \
      --assignee-principal-type "$principal_type" \
      --role "$role" \
      --scope "$scope" -o none
    echo "Assigned '$role' to $assignee"
  else
    echo "Role assignment already exists: '$role' on $assignee"
  fi
}

RG_SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"

CURRENT_USER_ID="$(az ad signed-in-user show --query id -o tsv)"
assign_role "$CURRENT_USER_ID" "Azure Service Bus Data Owner" "$RG_SCOPE" "User"


assign_role "$(principal_id "$WORKLOAD_A_IDENTITY")" "Azure Service Bus Data Receiver" "$RG_SCOPE" "ServicePrincipal"
assign_role "$(principal_id "$WORKLOAD_B_IDENTITY")" "Azure Service Bus Data Receiver" "$RG_SCOPE" "ServicePrincipal"
assign_role "$(principal_id "$WORKLOAD_C_IDENTITY")" "Azure Service Bus Data Receiver" "$RG_SCOPE" "ServicePrincipal"


if [[ -n "${KV_SCOPE:-}" ]]; then
  assign_role "$(principal_id "$KEDA_IDENTITY")" "Key Vault Secrets User" "$RG_SCOPE"
fi

echo "Role assignments complete. (KEDA identity intentionally has no Service Bus role.)"
