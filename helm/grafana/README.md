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
| http://grafana.localhost:9999 | GitHub login (cloudhonk org members) or `admin` / `changeme` |

## GitHub OAuth login

Grafana is configured to allow sign-in via GitHub OAuth, restricted to members of
the `cloudhonk` GitHub org (`allowed_organizations: cloudhonk` in `values.yaml`).
The local `admin`/`changeme` account still works as a fallback.

The OAuth `client_id`/`client_secret` are **not** stored in this chart or in
plaintext in git. They're read from files inside a Secret named
`grafana-github-oauth`, mounted at `/etc/secrets/github-oauth/` (see
`extraSecretMounts` in `values.yaml`). The secret manifest itself is
committed to git SOPS-encrypted at `secrets/grafana-github-oauth.enc.yaml`
(see the root README's Secrets Management section) and applied with
`make apply-secrets` - never templated by Helm.

### One-time setup

1. Create a GitHub OAuth App: https://github.com/organizations/cloudhonk/settings/applications
   (or https://github.com/settings/developers for a personal app if you don't
   have org admin rights) with:
   - **Homepage URL**: `http://grafana.localhost:9999`
   - **Authorization callback URL**: `http://grafana.localhost:9999/login/github`
2. Copy the generated **Client ID** and **Client Secret**.
3. The secret is stored SOPS-encrypted (against your SSH key) at
   `secrets/grafana-github-oauth.enc.yaml` - see the root
   [README's Secrets Management section](../../README.md#secrets-management)
   for the full pattern. To edit it with new credentials:
   ```
   make edit-secret FILE=secrets/grafana-github-oauth.enc.yaml
   ```
   this opens `$EDITOR` with the decrypted content; save and it re-encrypts
   automatically. Never commit a decrypted version of this file.
4. Apply the secret and upgrade the release:
   ```
   make apply-secrets
   make install-grafana
   ```
   (`make install-grafana` already depends on `apply-secrets`, so
   `make install-grafana` alone is enough after the first time.)

