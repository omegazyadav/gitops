# prometheus

Helm wrapper chart for [Prometheus](https://prometheus.io) (`prometheus 29.9.0`) deployed in the `monitoring` namespace.

## What it does

- Deploys the Prometheus server as the central **metrics store** for the observability stack.
- Enables the **OTLP receiver** and **remote-write receiver** via extra flags, so the OTel Collector ([`otel-cluster`](../otel-cluster/README.md) and [`otel-node`](../otel-node/README.md)) can push metrics over OTLP/HTTP without Prometheus scraping anything itself.
- Exposes Prometheus UI at `http://prometheus.localhost:8080` via ingress.
- All built-in Kubernetes scrape configs (pods, nodes, endpoints, etc.) are disabled — scraping is delegated entirely to the OTel Collector.
- Alertmanager is enabled for future alerting rules.
- Sets a global `cluster=local` external label on all metrics.
- Retention: **3 days**.

## Key values

| Value | Default |
|---|---|
| `prometheus.server.retention` | `3d` |
| `prometheus.server.extraFlags` | `web.enable-remote-write-receiver`, `web.enable-otlp-receiver` |
| `prometheus.server.persistentVolume.size` | `1Gi` |
| `prometheus.server.resources.requests` | `cpu: 100m, memory: 800Mi` |
| `prometheus.server.resources.limits` | `cpu: 500m, memory: 2Gi` |
| `prometheus.alertmanager.enabled` | `true` |
| `prometheus.kube-state-metrics.enabled` | `false` |
| `prometheus.prometheus-node-exporter.enabled` | `false` |

## Access

| URL | Credentials |
|---|---|
| http://prometheus.localhost:8080 | — |
