# Contributing

- Use branches + PRs; keep changes small and scoped.
- Run `terraform fmt -check`, `kubectl kustomize` (lint), and `yamllint` before PRs.
- Avoid provider‑specific logic in app manifests; keep cloud‑specific bits in `environments/*`.
