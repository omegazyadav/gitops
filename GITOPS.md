# GitOps entrypoint

GitOps entrypoint for ArgoCD (installed via `helm/argocd`, see `make install-argocd`).

## Structure

- `root.yaml` — the "app of apps" root `Application`. It watches this
  repo's `apps/` folder and creates a real ArgoCD `Application` for
  every manifest found there. Apply this once to bootstrap everything else:
  ```
  kubectl apply -f root.yaml
  ```
- `apps/<chart>.yaml` — one `Application` per Helm chart under `helm/`.
  Each points at `helm/<chart>` on the `main` branch and deploys it to its
  usual namespace (matching the `NAMESPACE_*` values in the root `Makefile`).

Each app is **fully independent** — the `sync-wave` annotation only affects
ordering when multiple apps sync together (e.g. bootstrapping the whole
stack from scratch); it does not couple their lifecycles day-to-day.

## Common day-to-day operations

Just want to run Grafana today and leave everything else alone? Use the
ArgoCD CLI or UI (`https://argocd.localhost:9999`) on that one Application:

```bash
# Sync just grafana (pull latest from git and apply)
argocd app sync grafana

# Stop auto-syncing grafana (edit only that Application's source, doesn't
# touch other apps) - either via UI "Disable Auto-Sync", or:
argocd app set grafana --sync-policy none

# Remove grafana entirely (and its resources) without affecting anything
# else in the stack
argocd app delete grafana
```

Equivalent `kubectl` versions (no ArgoCD CLI needed):
```bash
kubectl -n argocd patch application grafana --type merge \
  -p '{"spec":{"syncPolicy":null}}'   # disable auto-sync

kubectl -n argocd delete application grafana   # delete just this app
```

## Adding a new chart

1. Create `helm/<new-chart>/` as usual.
2. Copy an existing file in `apps/` (e.g. `apps/jaeger.yaml`) to
   `apps/<new-chart>.yaml`, updating `metadata.name`, `spec.source.path`,
   and `spec.destination.namespace`.
3. Commit and push - the root `otel-stack` Application (self-healing, auto
   sync) will pick up the new file and create the Application for you
   within its next reconcile loop (or run `argocd app sync otel-stack` /
   `kubectl -n argocd annotate application otel-stack argocd.argoproj.io/refresh=hard --overwrite`
   to force it immediately).
