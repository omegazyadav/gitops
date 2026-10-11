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

# 2. Install ArgoCD (also pre-seeds Istio's CRDs via `install-crds` - see below)
make install-argocd

# 3. Install ingress (core)
make install-app APP=ingress
```

`install-argocd` depends on `install-crds`, which applies Istio's `base`
chart (CRDs only, via plain `helm template | kubectl apply`, not through
ArgoCD) first. This breaks a bootstrap chicken-and-egg: ArgoCD's own chart
can optionally expose itself via an Istio `Gateway`/`VirtualService`
(`helm/argocd` → `istio.enabled`), which fails to render without Istio's
CRDs already present — but Istio itself is normally installed *by* ArgoCD
(`make install-tier TIER=bootstrap`). `install-crds` only seeds the CRDs; the
actual Istio control plane (`istiod`/`istio-ingressgateway`) still comes up
later, managed by ArgoCD as usual.

`apps/bootstrap/` is the one exception: it's an app-of-apps grouping the 3 Istio pieces (`istio-base`/`istiod`/`istio-ingressgateway`) that must stay ordered relative to each other (see below). Every other component, including `ingress`, `kuberay-operator`, and `mlmodel-ray`, is just a standalone folder under `apps/<name>/` that you install explicitly. Nothing is installed by default; you always choose what to bring up.

Access the ArgoCD UI at `http://argocd.localhost:9999` (`admin` / initial password):
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

## GitOps structure: one folder per component, install-on-demand

- `apps/<name>/application.yaml` — every component (including `ingress`), each its own standalone folder/entity. None of these exist on the cluster until you install them explicitly via `make install-app`/`install-tier`. Each one carries `syncPolicy.automated` baked in, so once installed it's fully self-managing (no manual `argocd app sync` needed) until you uninstall it. The one exception is `apps/bootstrap/`: since `istio-ingressgateway` needs `istiod`'s webhook to exist first, its 3 sub-Applications (`istio-base.yaml`, `istiod.yaml`, `istio-gateway.yaml`) carry no `tier` label and are only ever synced as managed resources of one parent `apps/bootstrap/application.yaml` (an app-of-apps pointed at that folder) — this is required because independent top-level Applications sync on their own schedule with no cross-Application coordination at all. (`kuberay-operator`/`mlmodel-ray` have a similar theoretical CRDs-before-workload ordering, but are kept as 2 fully independent standalone Applications rather than wrapped the same way — same tradeoff larger production ArgoCD setups make for Ray.) We don't add `argocd.argoproj.io/sync-wave` on top of the `bootstrap` grouping, though: `selfHeal` reconciles any ordering hiccup on its own within a few minutes, so the extra annotation isn't worth the added complexity. `make install-tier`/`uninstall-tier` picks up every non-`kustomization.yaml` file carrying the `tier` label in each folder.

This split decouples **install** (does the `Application` exist at all — an explicit, deliberate action) from **sync** (once installed, ArgoCD keeps it healthy automatically). Since every component lives in its own folder, you can install/remove exactly the ones you're experimenting with instead of all ~100s of charts at once. Related components still share a `tier: <name>` label (e.g. `prometheus`, `otel`, `bootstrap`, `kuberay`, `app`) so you can install/remove them together when useful, or one at a time.

### Makefile targets

```bash
make install-app APP=ingress         # install a single component (e.g. core ingress)
make uninstall-app APP=demo-app      # remove it (cascade-deletes its resources)
make install-tier TIER=prometheus    # install every component labeled tier=prometheus
make uninstall-tier TIER=prometheus  # remove every component labeled tier=prometheus
```

To add a new chart: create `helm/<new-chart>/` and `apps/<new-chart>/application.yaml` — copy an existing one, update `metadata.name`, `spec.source.path`, `spec.destination.namespace`, `tier` label — then commit and push.

## Istio (learning setup, runs alongside ingress-nginx)

`apps/bootstrap/application.yaml` (`tier: bootstrap`, install with `make install-tier TIER=bootstrap`) is an app-of-apps pointed at `apps/bootstrap/`, which in turn manages `istio-base.yaml`, `istiod.yaml`, and `istio-gateway.yaml` — installing the upstream Istio Helm charts into `istio-system`. The app-of-apps wrapper (instead of 3 independent top-level Applications) matters because `istio-ingressgateway`'s pod relies on istiod's sidecar-injector webhook to rewrite its placeholder `image: auto` at admission time, which only works once istiod (and its webhook) is up; independent top-level Applications sync on their own schedule with zero cross-Application coordination. We don't add explicit `sync-wave` ordering between the three on top of that, though — `selfHeal` converges any transient race on its own within a few minutes. The Istio ingress gateway is exposed via NodePort `30080`/`30443`, mapped in `kind.yaml` to host ports `8080`/`8443`.

`helm/demo-app` gets an additional `Gateway` + `VirtualService` (disabled by default via `istio.enabled: false`, turned on for `demo-app` in `apps/demo-app/application.yaml`) routing the **same host** (`demo-app.localhost`) the nginx `Ingress` already uses, to the same backend `Service`. The two paths are distinguished only by port.

## Further docs

- `helm/<chart>/README.md` — per-component configuration details
- `helm/argocd/README.md` — SOPS/secrets decryption setup

## License

MIT
