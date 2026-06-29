#!/usr/bin/env bash

# Create necessary Azure resources

set -euo pipefail
source "$(dirname "$0")/00-variables.sh"

# Create the RG if not present
if ! az group show --name "$RESOURCE_GROUP"; then
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION" -o none
  echo "Created resource group: $RESOURCE_GROUP"
else
  echo "Resource group already exists: $RESOURCE_GROUP"
fi

# Create the AKS cluster if not present
if ! az aks show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP"; then
  az aks create \
    --name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --node-count 1 \
    --node-vm-size Standard_D4ds_v6 \
    --os-sku AzureLinux \
    --enable-oidc-issuer \
    --enable-workload-identity \
    --generate-ssh-keys \
    -o none
  echo "Created AKS cluster: $CLUSTER_NAME"
else
  echo "AKS cluster already exists: $CLUSTER_NAME"
fi

# Create the service bus namespaces, and queues if they do not exist. 
for SB_NS in "$SB_A_NAMESPACE" "$SB_B_NAMESPACE" "$SB_C_NAMESPACE"; do
  if ! az servicebus namespace show --name "$SB_NS" --resource-group "$RESOURCE_GROUP"; then
    az servicebus namespace create \
      --name "$SB_NS" \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" \
      --sku Standard -o none
    
    az servicebus queue create --namespace-name "$SB_NS" --name "$SB_QUEUE" --resource-group "$RESOURCE_GROUP"
    echo "Created Service Bus namespace: $SB_NS"
    echo "Created Service Bus queue: $SB_QUEUE"
  else
    echo "Service Bus namespace already exists: $SB_NS"
  fi
done

# Create managed identities if they don't exist
for IDENTITY in "$KEDA_IDENTITY" "$WORKLOAD_A_IDENTITY" "$WORKLOAD_B_IDENTITY" "$WORKLOAD_C_IDENTITY"; do
  if ! az identity show --name "$IDENTITY" --resource-group "$RESOURCE_GROUP"; then
    az identity create \
      --name "$IDENTITY" \
      --resource-group "$RESOURCE_GROUP" \
      --location "$LOCATION" -o none
    echo "Created managed identity: $IDENTITY"
  else
    echo "Managed identity already exists: $IDENTITY"
  fi
done

# Print the clientId of each identity, just for reference
echo "==== clientIds (use these in the k8s YAML) ===="
for IDENTITY in "$KEDA_IDENTITY" "$WORKLOAD_A_IDENTITY" "$WORKLOAD_B_IDENTITY" "$WORKLOAD_C_IDENTITY"; do
  CLIENT_ID="$(az identity show --name "$IDENTITY" --resource-group "$RESOURCE_GROUP" --query clientId -o tsv)"
  printf "%-22s clientId=%s\n" "$IDENTITY" "$CLIENT_ID"
done
