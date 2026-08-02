# grafana

Helm wrapper chart for [Grafana](https://grafana.com) (`grafana 8.10.4`) deployed in the `monitoring` namespace.

## What it does

- Exposes Grafana at `http://grafana.localhost:8080` via ingress.
- Pre-provisions three datasources:
  - **Prometheus** (`http://prometheus-server.monitoring.svc.cluster.local`) — default datasource.
  - **Loki** (`http://loki-gateway.loki.svc.cluster.local`) — with a derived field that links `trace_id` labels to Jaeger.
  - **Jaeger** (`http://jaeger.monitoring.svc.cluster.local:16686`) — with traces-to-logs correlation back to Loki.
- Enables the **dashboard sidecar**: any ConfigMap labelled `grafana_dashboard: "1"` in any namespace is auto-loaded as a dashboard (used by [`dev/apps/otel-app`](../../apps/otel-app/README.md)).
- Persists data to a 2 Gi PVC (`standard` StorageClass).

## Key values

| Value | Default |
|---|---|
| `grafana.adminPassword` | `changeme` |
| `grafana.ingress.hosts` | `[grafana.localhost]` |
| `grafana.persistence.size` | `2Gi` |
| `grafana.resources.requests` | `cpu: 100m, memory: 256Mi` |
| `grafana.resources.limits` | `cpu: 500m, memory: 512Mi` |

## Access

| URL | Credentials |
|---|---|
| http://grafana.localhost:8080 | `admin` / `changeme` |
