#!/usr/bin/env bash
set -euo pipefail

# Install ExternalDNS via Helm with provider-specific values
# Example for AWS; swap values for GCP/Azure.
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ >/dev/null
helm repo update >/dev/null
helm upgrade --install external-dns external-dns/external-dns \
  --namespace ingress-nginx --create-namespace \
  -f cluster-addons/external-dns/values-aws.yaml

echo "Remember to configure cert-manager Issuer/ClusterIssuer for TLS."
