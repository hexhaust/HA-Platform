# Architecture

- Global DNS (weighted/latency) points to each region’s public ingress.
- Argo Rollouts injects canary/blue‑green traffic via Ingress‑NGINX annotations.
- Managed data per region; async replication where needed.
