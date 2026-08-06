# otel-stack

A local Kubernetes observability stack (kind), deployed and managed via ArgoCD GitOps.

## Stack

| Layer | Technology |
|---|---|
| Metrics | Prometheus, VictoriaMetrics |
| Logging | Loki |
| Tracing | Jaeger |
| Collection | OpenTelemetry Collector (cluster + node) |
| Dashboards | Grafana |
| Ingress | ingress-nginx |
| Storage | MinIO, Postgres |
| Demo workload | `helm/demo-app` — OTel-instrumented Go service |
| GitOps | ArgoCD |
| Secrets | SOPS + age (decrypted inline by ArgoCD's repo-server) |

Every component is a Helm chart under `helm/<chart>`, each wired to ArgoCD via a matching `Application` manifest under `apps/<chart>.yaml`.

## Bootstrap (ArgoCD)

```bash
# 1. Create the local kind cluster
make create-cluster

# 2. Install ArgoCD
make install-argocd

# 3. Bootstrap everything else (the "app of apps")
kubectl apply -f root.yaml
```

From here, ArgoCD auto-syncs every chart in `apps/` from git — no further manual `helm`/`kubectl` steps needed.

Access the ArgoCD UI at `http://argocd.localhost:9999` (`admin` / initial password):
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

## GitOps structure

- `root.yaml` — the "app of apps" root `Application`. Watches `apps/` and creates a real ArgoCD `Application` for every manifest found there.
- `apps/<chart>.yaml` — one `Application` per Helm chart under `helm/<chart>`, each fully independent.

Manage apps individually with the ArgoCD CLI/UI or `kubectl`:
```bash
argocd app sync grafana                          # sync just grafana
argocd app set grafana --sync-policy none         # disable auto-sync
argocd app delete grafana                         # remove it entirely
```

To add a new chart: create `helm/<new-chart>/`, copy an existing file in `apps/` to `apps/<new-chart>.yaml` (update `metadata.name`, `spec.source.path`, `spec.destination.namespace`), then commit and push.

## Further docs

- `helm/<chart>/README.md` — per-component configuration details
- `helm/argocd/README.md` — SOPS/secrets decryption setup

## License

MIT
