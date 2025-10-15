# Operations

- Health checking: L7 probes `/healthz`.
- Release process: observe SLOs during canary; auto‑promote on success or abort.
- Failover: DNS weights → 0 on failing region. ExternalDNS + provider health checks recommended.
