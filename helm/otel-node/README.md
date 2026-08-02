# otel-node

Helm wrapper chart for the [OpenTelemetry Collector](https://opentelemetry.io/docs/collector) (`opentelemetry-collector 0.158.0`) running as a **DaemonSet** in the `monitoring` namespace. Handles node-local signal collection.

## What it does

- Runs as a **DaemonSet** (`otel-node`) — one pod per node, required for receivers that can only see the local node.
- Enables four presets:
  - **kubernetesAttributes** — enriches signals with pod/namespace/node metadata.
  - **kubeletMetrics** (`kubeletstats` receiver) — collects per-node/pod/container resource metrics from the kubelet API. Uses `insecure_skip_verify: true` because the kind kubelet cert has no IP SAN.
  - **hostMetrics** (`hostmetrics` receiver) — collects CPU, memory, disk, network metrics from the node OS.
  - **logsCollection** (`filelog` receiver) — tails `/var/log/pods` on each node to collect all pod stdout/stderr logs. Collector's own logs are excluded to prevent a feedback loop.
- All push-based ports (OTLP, Jaeger, Zipkin) are disabled — this collector is pull-only.
- Exports:
  - **Metrics** → Prometheus (`prometheus-server.monitoring.svc.cluster.local`) via OTLP/HTTP.
  - **Logs** → Loki (`loki-gateway.loki.svc.cluster.local`) via OTLP/HTTP.
- Adds `environment=dev` and `k8s.cluster.name=test-cluster` resource attributes to all signals.
- Memory limiter: 80% limit, 25% spike limit.

## Pipelines

| Pipeline | Receivers | Exporters |
|---|---|---|
| metrics | `kubeletstats`, `hostmetrics` | Prometheus |
| logs | `filelog` | Loki |
| traces | (none) | — |

## Key values

| Value | Default |
|---|---|
| `collector.mode` | `daemonset` |
| `collector.image.repository` | `otel/opentelemetry-collector-k8s` |
| `collector.resources.requests` | `cpu: 100m, memory: 128Mi` |
| `collector.resources.limits` | `cpu: 300m, memory: 512Mi` |

## See also

- [`otel-cluster`](../otel-cluster/README.md) — Deployment collector for cluster-level metrics and OTLP ingestion from apps.
