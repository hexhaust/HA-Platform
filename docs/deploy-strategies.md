# Deploy Strategies

- **Rolling**: `apps/hello/deployment-rolling.yaml`
- **Canary**: `apps/hello/rollout-canary.yaml` (uses `stableIngress: hello` and stable/canary services)
- **Blue/Green**: `apps/hello/rollout-bluegreen.yaml` (active & preview services)
