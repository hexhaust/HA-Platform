#!/usr/bin/env bash
set -euo pipefail
: "${KUBECONFIG:?Set KUBECONFIG to your cluster kubeconfig}"

kubectl apply -k cluster-addons/base
echo "Waiting for ingress-nginx controller..."
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=5m || true

echo "Addons installed."
