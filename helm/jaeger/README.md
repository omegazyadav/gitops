# jaeger

Helm wrapper chart for [Jaeger](https://www.jaegertracing.io) (`jaeger 4.8.0`) deployed in the `monitoring` namespace.

## What it does

- Runs in **all-in-one** mode (collector, query, and UI in a single pod) with **in-memory storage** — no external datastore needed.
- Exposes the Jaeger UI at `http://jaeger.localhost:8080` via ingress.
- Opens OTLP receivers so the OTel Collector ([`otel-cluster`](../otel-cluster/README.md)) can forward traces directly:
  - gRPC: `:4317`
  - HTTP: `:4318`
- Disables Cassandra provisioning (uses memory storage instead).

## Key values

| Value | Default |
|---|---|
| `jaeger.allInOne.enabled` | `true` |
| `jaeger.storage.type` | `memory` |
| `jaeger.provisionDataStore.cassandra` | `false` |
| `jaeger.jaeger.ingress.hosts` | `[jaeger.localhost]` |
| `jaeger.collector.service.otlp.grpc.port` | `4317` |
| `jaeger.collector.service.otlp.http.port` | `4318` |

## Access

| URL | Credentials |
|---|---|
| http://jaeger.localhost:8080 | — |

## Notes

In-memory storage means traces are lost on pod restart. For persistent storage, switch `jaeger.storage.type` to `elasticsearch` or `cassandra` and enable the respective datastore.
