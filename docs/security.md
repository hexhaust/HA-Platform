# Security

- TLS via cert-manager ClusterIssuer/Issuer (not included: set your ACME/DNS01 or HTTP01).
- Namespaced RBAC; avoid cluster‑admin for apps.
- Image scanning in CI (stub).
