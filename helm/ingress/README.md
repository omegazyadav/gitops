# ingress

Helm wrapper chart for [ingress-nginx](https://kubernetes.github.io/ingress-nginx) (`ingress-nginx 4.12.2`) deployed in the `ingress-nginx` namespace.

## What it does

- Runs as the **default IngressClass** so Ingress resources need no explicit `ingressClassName`.
- Uses **hostPort** (`:80` / `:443`) so traffic flows: `Mac:80 → kind-node:80 → nginx pod` without a LoadBalancer.
- Uses `ClusterIP` service type since traffic enters via hostPort on the pod.
- Scheduled exclusively on the kind control-plane node via `nodeSelector: ingress-ready: "true"` (set in `kind.yaml`) and a toleration for `node-role.kubernetes.io/control-plane`.

## Key values

| Value | Default |
|---|---|
| `ingress-nginx.controller.hostPort.enabled` | `true` |
| `ingress-nginx.controller.hostPort.ports.http` | `80` |
| `ingress-nginx.controller.service.type` | `ClusterIP` |
| `ingress-nginx.controller.ingressClassResource.default` | `true` |

## Notes

All services in this stack are exposed through this controller on port `8080` (kind extraPortMappings forward host `8080 → node 80`). Add `*.localhost` entries to `/etc/hosts` if CLI tools need resolution.
