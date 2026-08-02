# otel-cluster

Helm wrapper chart for the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector) (`opentelemetry-collector 0.158.0`) running as a **Deployment** in the `monitoring` namespace. Handles cluster-wide signal collection.

## What it does

- Runs as a single-replica **Deployment** (`otel-cluster`) — cluster-scoped collection that doesn't need to be on every node.
- Enables two presets:
  - **kubernetesAttributes** — enriches all signals with pod/namespace/node metadata from the K8s API.
  - **clusterMetrics** (`k8s_cluster` receiver) — collects cluster-level metrics (kube-state-like node/pod/container status).
- Receives OTLP over gRPC (`:4317`) and HTTP (`:4318`) from instrumented applications.
- Scrapes pod metrics via **annotation-based discovery** (`prometheus/apps` receiver): pods annotated with `prometheus.io/scrape: "true"` are auto-discovered.
- Exports:
  - **Traces** → Jaeger (`jaeger.monitoring.svc.cluster.local:4317`) via OTLP/gRPC.
  - **Metrics** → Prometheus (`prometheus-server.monitoring.svc.cluster.local`) via OTLP/HTTP.
- Adds `environment=dev` and `k8s.cluster.name=test-cluster` resource attributes to all signals.
- Memory limiter: 80% limit, 25% spike limit.

## Pipelines

| Pipeline | Receivers | Exporters |
|---|---|---|
| traces | `otlp` | Jaeger |
| metrics | `otlp`, `k8s_cluster`, `prometheus/apps` | Prometheus |
| logs | (none) | — |

## Key values

| Value | Default |
|---|---|
| `collector.mode` | `deployment` |
| `collector.replicaCount` | `1` |
| `collector.image.repository` | `otel/opentelemetry-collector-k8s` |
| `collector.resources.requests` | `cpu: 100m, memory: 128Mi` |
| `collector.resources.limits` | `cpu: 500m, memory: 512Mi` |

## See also

- [`otel-node`](../otel-node/README.md) — DaemonSet collector for node-local metrics and log collection.
