#!/usr/bin/env bash
# Apply rendered k8s manifests to the cluster.
# Run scripts/05-render-k8s.sh first to generate the manifests.
set -euo pipefail

kubectl apply -f k8s/service-accounts.yaml
kubectl apply -f k8s/trigger-authentications.yaml
kubectl apply -f k8s/deployments.yaml
kubectl apply -f k8s/scaledobjects.yaml

echo
echo "All manifests applied."
