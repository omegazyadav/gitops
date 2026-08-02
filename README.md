# otel-demo

Observability stack using **Prometheus**, **Loki**, and **OpenTelemetry**.

---

## Stack

| Layer | Technology |
|---|---|
| Metrics | Prometheus |
| Logging | Logrus → Loki (HTTP push) |
| Tracing | OpenTelemetry (OTLP) |
| Container | Docker (multi-stage build) |
| Orchestration | Kubernetes |

---

## Observability

### Metrics (Prometheus)
Exposed at `/metrics`. Two custom metrics are instrumented:

- `note_app_requests_total` — HTTP request counter labeled by `method`, `path`, `status`
- `note_app_request_duration_seconds` — Histogram of response latency labeled by `method`, `path`

### Logs (Loki)
Structured JSON logs via `logrus` are pushed directly to Loki using a custom HTTP hook in `loki.go` — no `promtail` or `loki-client-go` dependency required.

Each log entry includes `method`, `path`, `status`, and `duration` fields.

Configure the Loki endpoint via environment variable:
```bash
LOKI_URL=http://loki:3100/loki/api/v1/push
```

### Tracing (OpenTelemetry)
Traces are exported via OTLP HTTP to a configured endpoint (Tempo, Jaeger, etc.).

Configure via standard OTEL env vars:
```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo:4318
OTEL_SERVICE_NAME=note-app
```

---

## Kubernetes Deployment

```bash
# Deploy
make deploy

# Verify
kubectl get pods
kubectl logs -l app=note-app
```

---

## Secrets Management

Secrets are managed with [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age),
encrypted against your **existing SSH key** (RSA or ed25519 - no separate
age keypair needed, `age` supports SSH keys as recipients natively). This
lets encrypted secret manifests be safely committed to git in `secrets/`.

Recipients are configured in `~/.sops.yaml` (kept outside the repo,
per-machine/per-user - SOPS automatically discovers it by walking up from
the current directory, so no repo-local config is needed):
```yaml
creation_rules:
  - path_regex: secrets/.*\.enc\.yaml$
    age: >-
      ssh-rsa AAAAB3N... your-username
```

> Each contributor needs their own `~/.sops.yaml` entry (their own SSH
> public key as recipient) to encrypt/decrypt secrets on their machine. If
> multiple people need access to the same secret, list multiple recipients
> (one per line, comma-separated) in the `age:` field.

### Day-to-day usage

```bash
# Apply all encrypted secrets to the cluster (also run automatically by
# `make install` / `make install-grafana`)
make apply-secrets

# Edit an existing encrypted secret (opens $EDITOR with decrypted content,
# re-encrypts automatically on save)
make edit-secret FILE=secrets/grafana-github-oauth.enc.yaml

# Create a brand new encrypted secret from scratch
cat > secrets/my-secret.enc.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: my-namespace
type: Opaque
stringData:
  key: value
EOF
sops -e -i secrets/my-secret.enc.yaml
```

If your SSH key isn't `~/.ssh/id_rsa`, override it:
```bash
make apply-secrets SOPS_AGE_SSH_PRIVATE_KEY_FILE=~/.ssh/id_ed25519
```

> Only the files under `secrets/*.enc.yaml` (already SOPS-encrypted) should
> ever be committed. Never commit a decrypted secret manifest.

Currently-managed secrets:
| Secret | Used by | Purpose |
|---|---|---|
| `secrets/grafana-github-oauth.enc.yaml` | `helm/grafana` | GitHub OAuth `client_id`/`client_secret` for Grafana login (see `helm/grafana/README.md`) |

Note: `alertmanager-slack-secret` (used by `helm/victoria-metrics`) is
currently applied via `helm upgrade ... --set slack.webhookUrl=...` rather
than a SOPS-encrypted file - see `helm/victoria-metrics/README.md` if present,
or migrate it into `secrets/` using the same pattern above.

---

## License

MIT
