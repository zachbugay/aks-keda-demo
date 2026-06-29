#!/usr/bin/env bash
set -euo pipefail

# Add your variables here
export SUBSCRIPTION_ID="<YOUR SUBSCRIPTION ID>"
export TENANT_ID="<YOUR TENANT ID>"
export RESOURCE_GROUP="<YOUR RESOURCE GROUP>"
export LOCATION="<YOUR DESIRED AZURE LOCATION>"
export CLUSTER_NAME="<YOUR AKS CLUSTER NAME>"

# Managed Identity names
export KEDA_IDENTITY="id-keda"
export WORKLOAD_A_IDENTITY="id-workload-a"
export WORKLOAD_B_IDENTITY="id-workload-b"
export WORKLOAD_C_IDENTITY="id-workload-c"

# The AKS KEDA add-on deploys the operator into kube-system as "keda-operator".
export KEDA_SA_NAMESPACE="kube-system"
export KEDA_SA_NAME="keda-operator"

# Kubernetes namespaces and service accounts
export WORKLOAD_A_NAMESPACE="app-a"
export WORKLOAD_A_SA="workload-a-sa"

export WORKLOAD_B_NAMESPACE="app-b"
export WORKLOAD_B_SA="workload-b-sa"

export WORKLOAD_C_NAMESPACE="app-c"
export WORKLOAD_C_SA="workload-c-sa"

# Service Bus Namespaces
export SB_A_NAMESPACE="sb-workload-a"
export SB_B_NAMESPACE="sb-workload-b"
export SB_C_NAMESPACE="sb-workload-c"

# Service Bus Queue
export SB_QUEUE="orders"

az account set --subscription "$SUBSCRIPTION_ID"
