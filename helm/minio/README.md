# minio

Helm wrapper chart for [MinIO](https://min.io) (`minio 5.4.0`) deployed in the `minio` namespace.

## What it does

- Runs in **standalone** mode — single-node, no distributed setup.
- Serves as the S3-compatible object storage backend for **Loki** (log chunks) and reserves a bucket for **Thanos** (if added later).
- Exposes two ingress endpoints:
  - **API**: `http://minio.localhost:8080` — S3 API used by Loki.
  - **Console**: `http://minio-console.localhost:8080` — browser UI for browsing buckets.
- Creates buckets and a dedicated Loki user on startup.

## Key values

| Value | Default |
|---|---|
| `minio.mode` | `standalone` |
| `minio.persistence.size` | `10Gi` |
| `minio.rootUser` | `minioadmin` |
| `minio.rootPassword` | `minioadmin` |
| `minio.resources.requests.memory` | `1Gi` |

## Buckets

| Bucket | Used by |
|---|---|
| `loki` | Loki log chunks, ruler, admin |
| `thanos` | Reserved (not yet used) |

## Users

| Access key | Policy | Used by |
|---|---|---|
| `loki` | `readwrite` | Loki S3 client |

## Access

| URL | Credentials |
|---|---|
| http://minio.localhost:8080 (API) | — |
| http://minio-console.localhost:8080 (Console) | `minioadmin` / `minioadmin` |
