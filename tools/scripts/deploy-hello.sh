#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-rolling}" # rolling | canary | bluegreen
kubectl apply -k apps/hello
case "$MODE" in
  rolling)    kubectl apply -f apps/hello/deployment-rolling.yaml ;;
  canary)     kubectl apply -f apps/hello/rollout-canary.yaml ;;
  bluegreen)  kubectl apply -f apps/hello/rollout-bluegreen.yaml ;;
  *)          echo "Unknown mode: $MODE" && exit 1 ;;
esac
echo "Deployed hello with strategy: $MODE"
