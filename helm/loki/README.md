# loki

Helm wrapper chart for [Loki](https://grafana.com/oss/loki) (`loki 7.0.0`) deployed in the `loki` namespace.

## What it does

- Runs in **single-binary** mode (all Loki components in one replica).
- Uses **MinIO** ([`dev/addons/minio`](../minio/README.md)) as the S3-compatible object store — chunks, ruler, and admin data all land in the `loki` bucket.
- Index stored via **TSDB** shipper with a 24-hour period; schema version `v13` effective from `2024-04-01`.
- Auth disabled (`auth_enabled: false`) — suitable for single-tenant dev use.
- Accepts structured metadata and log volume queries; retention set to **360 h (15 days)**.
- Pattern ingester enabled for log pattern analysis.
- Persists index/WAL to a 2 Gi PVC (`standard` StorageClass) at `/var/loki`.
- All distributed-mode replicas (backend, read, write, etc.) are zeroed out.

## Key values

| Value | Default |
|---|---|
| `loki.deploymentMode` | `SingleBinary` |
| `loki.loki.auth_enabled` | `false` |
| `loki.loki.storage.type` | `s3` |
| `loki.loki.storage.s3.endpoint` | `minio.minio.svc:9000` |
| `loki.loki.limits_config.retention_period` | `360h` |
| `loki.singleBinary.replicas` | `1` |
| `loki.singleBinary.persistence.size` | `2Gi` |
| `loki.singleBinary.resources.requests` | `cpu: 500m, memory: 800Mi` |

## Dependencies

Requires MinIO to be running first (sync-wave 1). MinIO credentials used: `accessKeyId: loki`, `secretAccessKey: loki-secret`.
