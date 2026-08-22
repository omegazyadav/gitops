# gitops

A local Kubernetes observability stack (kind), deployed and managed via ArgoCD GitOps.

## Stack

| Layer | Technology |
|---|---|
| Metrics | Prometheus, VictoriaMetrics |
| Logging | Loki |
| Tracing | Jaeger |
| Collection | OpenTelemetry Collector (cluster + node) |
| Dashboards | Grafana |
| Ingress | ingress-nginx, Istio (`istio-base`/`istiod`/`istio-ingressgateway`, learning setup) |
| Storage | MinIO, Postgres |
| Demo workload | `helm/demo-app` — OTel-instrumented Go service |
| GitOps | ArgoCD |
| Secrets | SOPS + age (decrypted inline by ArgoCD's repo-server) |

Every component is a Helm chart under `helm/<chart>`, each wired to ArgoCD via its own `apps/<chart>/application.yaml` — installed on demand (see below).

## Bootstrap (ArgoCD)

```bash
# 1. Create the local kind cluster
make create-cluster

# 2. Install ArgoCD
make install-argocd

# 3. Install ingress (core)
make install-app APP=ingress
```

There's no "app of apps" root anymore — every component, including `ingress`, is just a folder under `apps/<name>/` that you install explicitly. Nothing is installed by default; you always choose what to bring up.

Access the ArgoCD UI at `http://argocd.localhost:9999` (`admin` / initial password):
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

## GitOps structure: one folder per component, install-on-demand

- `apps/<name>/application.yaml` — every component (including `ingress`), each its own standalone folder/entity. None of these exist on the cluster until you install them explicitly via `make install-app`/`install-tier`. Each one carries `syncPolicy.automated` baked in, so once installed it's fully self-managing (no manual `argocd app sync` needed) until you uninstall it.

This split decouples **install** (does the `Application` exist at all — an explicit, deliberate action) from **sync** (once installed, ArgoCD keeps it healthy automatically). Since every component lives in its own folder, you can install/remove exactly the ones you're experimenting with instead of all ~100s of charts at once. Related components still share a `tier: <name>` label (e.g. `prometheus`, `otel`, `istio`, `app`) so you can install/remove them together when useful, or one at a time.

### Makefile targets

```bash
make argocd-list                     # what's installed (live Applications) + what's available in apps/
make install-app APP=ingress         # install a single component (e.g. core ingress)
make uninstall-app APP=demo-app      # remove it (cascade-deletes its resources)
make install-tier TIER=prometheus    # install every component labeled tier=prometheus
make uninstall-tier TIER=prometheus  # remove every component labeled tier=prometheus
```

To add a new chart: create `helm/<new-chart>/` and `apps/<new-chart>/application.yaml` — copy an existing one, update `metadata.name`, `spec.source.path`, `spec.destination.namespace`, `tier` label — then commit and push.

## Istio (learning setup, runs alongside ingress-nginx)

`apps/istio-base/application.yaml`, `apps/istiod/application.yaml`, and `apps/istio-ingressgateway/application.yaml` (all `tier: istio`, install with `make install-tier TIER=istio`) install the upstream Istio Helm charts into `istio-system` — nginx keeps handling its existing routes untouched. The Istio ingress gateway is exposed via NodePort `30080`/`30443`, mapped in `kind.yaml` to host ports `8080`/`8443` (separate from nginx's `9999`/`9443`).

`helm/demo-app` gets an additional `Gateway` + `VirtualService` (disabled by default via `istio.enabled: false`, turned on for `demo-app` in `apps/demo-app/application.yaml`) routing the **same host** (`demo-app.localhost`) the nginx `Ingress` already uses, to the same backend `Service`. The two paths are distinguished only by port.

## Further docs

- `helm/<chart>/README.md` — per-component configuration details
- `helm/argocd/README.md` — SOPS/secrets decryption setup

## License

MIT
