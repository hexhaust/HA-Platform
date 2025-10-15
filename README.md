# HA Platform — Multi‑Region, Active‑Active Kubernetes (AWS • GCP • Azure)

Production‑grade **reference platform** for running apps across **multiple regions** and **multiple clouds** with **active‑active traffic** and **progressive delivery**: **canary**, **blue/green**, and **rolling**.
Built around **Kubernetes**, **Argo Rollouts**, **Ingress‑NGINX**, **ExternalDNS**, **cert‑manager**, and a minimal **Prometheus/Grafana + OpenTelemetry** stack.

> ⚠️ This is a **reference**. You’ll need to plug in your cloud project/account IDs, IAM/roles, networking/CNI, TLS issuers, and DNS zone. Cloud resources cost money—destroy what you don’t need.

---

## Features

* 🌍 **Multi‑region, multi‑cloud:** EKS (AWS), GKE (GCP), AKS (Azure)
* ♻️ **Active‑active traffic:** serve from multiple regions at once; steer via **weighted or latency‑based DNS**
* 🚦 **Progressive delivery:** Canary & Blue/Green (via **Argo Rollouts**) + standard Rolling (native Kubernetes)
* ☸️ **K8s add‑ons:** Ingress‑NGINX, ExternalDNS, cert‑manager, optional Gateway API
* 🔭 **Observability:** Prometheus + Grafana (lightweight), OpenTelemetry Collector (export to your backend)
* 🔒 **Security:** TLS by default (via cert‑manager), namespaced RBAC, image provenance hooks (stub)

---

## Architecture (ASCII, no Mermaid)

```
Clients ──> Global DNS (weighted/latency) ──> Cloud LB ──> Ingress‑NGINX ──> Services
                                                    │
                                             Argo Rollouts
                                              (canary/blue‑green)
```

* **Global DNS**: Route 53 / Cloud DNS / Azure DNS with health‑checked **weighted or latency** routing
* **Ingress**: **Ingress‑NGINX** (same config on EKS/GKE/AKS)
* **Traffic shifts**: Argo Rollouts updates NGINX routing to send % of traffic to canary/preview
* **State**: Prefer **managed DBs per region** with replication; avoid cross‑region StatefulSets for hot paths

---

## Repository layout

```
ha-platform/
├─ README.md
├─ LICENSE
├─ CONTRIBUTING.md
├─ .gitignore
├─ docs/
│  ├─ architecture.md
│  ├─ deploy-strategies.md
│  ├─ operations.md
│  ├─ security.md
│  └─ observability.md
├─ apps/
│  └─ hello/                 # sample service with 3 deployment styles
│     ├─ kustomization.yaml
│     ├─ namespace.yaml
│     ├─ service.yaml        # stable/canary/preview services (see NOTE below on ports)
│     ├─ deployment-rolling.yaml
│     ├─ rollout-canary.yaml
│     ├─ rollout-bluegreen.yaml
│     ├─ ingress.yaml        # stable ingress; Rollouts adds canary ingress dynamically
│     └─ httproute.yaml      # (optional) Gateway API example
├─ cluster-addons/
│  ├─ base/
│  ├─ argo-rollouts/
│  ├─ ingress-nginx/
│  ├─ gateway-api/           # optional
│  ├─ cert-manager/
│  ├─ external-dns/
│  ├─ monitoring/
│  └─ opentelemetry/
├─ environments/
│  ├─ aws/us-east-1/cluster/terraform
│  ├─ aws/eu-west-1/cluster/terraform
│  ├─ gcp/us-central1/cluster/terraform
│  └─ azure/eastus/cluster/terraform
├─ modules/
│  ├─ eks/  gke/  aks/       # simplified cluster modules
│  └─ global-dns/            # stubs for cross-region weighted records
├─ .github/workflows/
│  ├─ validate.yml
│  └─ deploy.yml             # GitOps/manual stub
└─ tools/scripts/
   ├─ bootstrap-cluster.sh
   ├─ install-addons.sh
   ├─ deploy-hello.sh
   └─ smoke-test.sh
```

> **Port NOTE (important):** The sample container `ghcr.io/nginxdemos/hello:plain-text` listens on **port 80**.
> Make sure `apps/hello/service.yaml`’s `targetPort` matches **80** (not 8080). If yours says `8080`, switch to `80`.

---

## Prerequisites

* **CLI:** Terraform ≥ 1.6, kubectl ≥ 1.28, kustomize ≥ 5, Helm ≥ 3.12
* **Cloud CLIs:** `aws`, `gcloud`, `az` (authenticated & set to your projects/accounts/subscriptions)
* **DNS:** A zone you control (e.g., `example.com`)
* **Access:** IAM/roles to create clusters, networking, and LBs in your clouds

---

## Quick start (one region first)

> Start with **one cloud/region** to prove the flow. Repeat for others once stable.

1. **Create a cluster** (example: AWS us‑east‑1):

```bash
cd environments/aws/us-east-1/cluster/terraform
terraform init
terraform apply
# Use the kubeconfig command from outputs, e.g.:
aws eks update-kubeconfig --region us-east-1 --name ha-eks-us-east-1
```

*(GCP: `gcloud container clusters get-credentials ...`; Azure: `az aks get-credentials ...` — see module outputs.)*

2. **Install add‑ons** (Ingress‑NGINX, Argo Rollouts, Prom/Grafana, OTel, cert‑manager):

```bash
export KUBECONFIG=~/.kube/config   # or your kubeconfig path
bash tools/scripts/bootstrap-cluster.sh
```

3. **ExternalDNS** (pick the right values file for your cloud):

```bash
# AWS example; change the -f to values-gcp.yaml or values-azure.yaml as needed
bash tools/scripts/install-addons.sh
```

4. **TLS** (required): configure a cert‑manager Issuer/ClusterIssuer for your DNS (ACME HTTP‑01 or DNS‑01).
   Add your issuer manifests under `cluster-addons/cert-manager/` (not included out‑of‑box).

5. **Deploy the sample app** with your preferred strategy:

```bash
# rolling | canary | bluegreen
bash tools/scripts/deploy-hello.sh canary
```

6. **DNS**: Point `hello.example.com` at the public address/hostname of your ingress controller
   (or let ExternalDNS manage it if you annotated your Ingress with your domain and have the right RBAC/creds).

7. **Smoke test:**

```bash
bash tools/scripts/smoke-test.sh hello.example.com
```

---

## Progressive delivery (how to drive it)

### Rolling

* Uses native `Deployment` (`apps/hello/deployment-rolling.yaml`).
* Zero downtime with `maxSurge=1`, `maxUnavailable=0` (editable per your SLO).

### Canary (Argo Rollouts + NGINX)

* `apps/hello/rollout-canary.yaml` defines steps: **10% → 30% → 60%** with pauses.
* Argo Rollouts manipulates NGINX canary annotations; traffic shifts happen live.
* Observe metrics/logs during pauses; **promote** or **abort** via Argo Rollouts UI/CLI.

### Blue/Green (Argo Rollouts)

* `apps/hello/rollout-bluegreen.yaml` with `activeService` and `previewService`.
* Validate on the **preview** service; **promote** when ready (no mid‑percentage states).

> Choose **one** strategy at a time. `apps/hello/kustomization.yaml` includes common resources;
> the `deploy-hello.sh` script then applies the **one** rollout/deployment you pick.

---

## Multi‑region & active‑active

1. **Replicate clusters** in additional regions/clouds:

   * AWS: copy `environments/aws/us-east-1` → `eu-west-1` (already scaffolded), update variables
   * GCP: add more regions (e.g., `europe-west1`)
   * Azure: add more regions (e.g., `westeurope`)

2. **Install add‑ons** on each cluster (same commands).

3. **Expose the same hostname** (`hello.example.com`) in every region.

   * ExternalDNS can manage per‑region records (e.g., `us-east-1.hello.example.com`)
   * Use **Global DNS** to create **weighted/latency** A/AAAA/CNAME records that point to each region’s LB
     (see `modules/global-dns/` stubs; or manage these at your DNS provider/registrar).

4. **Health checks + fail‑open**: configure DNS health checks to **de‑weight** unhealthy regions automatically.

---

## Observability

* **Prometheus/Grafana**: basic dashboards are included as a ConfigMap stub (replace with your chart/values).
* **OpenTelemetry Collector**: receives OTLP and exports to **logging** by default — change the exporter to your backend.
* **Release annotations & SLOs**: annotate releases and wire alerts to **error budgets**, not raw metrics.

See: `docs/observability.md`

---

## Security

* **TLS by default**: Use cert‑manager Issuer/ClusterIssuer (ACME HTTP‑01/DNS‑01).
* **Least privilege**: Namespaced RBAC for apps; avoid cluster‑admin outside automation/bootstrap.
* **Supply chain** (stub): image scanning, SBOM, and signing belong in CI; wire your pipeline to enforce these.

See: `docs/security.md`

---

## Operations

* **Health endpoints**: L7 `/healthz` for LB probes; readiness gates on Pods.
* **Rollouts**: Observe metrics during canary pauses; **promote/abort** intentionally.
* **DNS failover**: Weighted or latency policies + health checks de‑weight failing regions.

See: `docs/operations.md`

---

## Provider specifics (notes)

* **AWS/EKS**: Fill in IAM roles, subnets, and VPC IDs in `modules/eks`. Decide on CNI (VPC CNI/Cilium).
* **GCP/GKE**: Set `project` and networking (`network`, `subnetwork`) in `modules/gke`.
* **Azure/AKS**: Provide resource group and identity of the cluster in `modules/aks`.

> The Terraform modules here are **skeletal** to show integration points. In production, pin versions, add remote state, workspaces, and policy checks (OPA/Sentinel).

---

## CI/CD

This template ships with:

* **`.github/workflows/validate.yml`** — basic Terraform format and YAML lint
* **`.github/workflows/deploy.yml`** — manual stub (expecting **GitOps** or manual `kubectl apply -k`)

Bring your own CI for build, scan, SBOM, and image signing.

---

## Troubleshooting

* **Ingress returns 404**: confirm `ingress-nginx` is Ready and your Ingress `host` matches DNS.
* **Canary has no effect**: check Argo Rollouts controller health and NGINX canary annotations.
* **Service has no endpoints**: ensure **Service `targetPort` = container `containerPort` (80)**.
* **DNS not updating**: verify ExternalDNS creds/RBAC and `domainFilters` in `values-*.yaml`.

---

## Cleanup

Destroy resources in each environment to avoid costs:

```bash
terraform -chdir=environments/aws/us-east-1/cluster/terraform destroy
# repeat for other regions/clouds
```

---

## Contributing & License

* See `CONTRIBUTING.md` for guidelines
* Licensed under **MIT** (see `LICENSE`)

---
