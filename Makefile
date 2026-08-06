NAMESPACE_DEMO_APP          := default
NAMESPACE_POSTGRES          := default
NAMESPACE_OTEL_STACK        := monitoring
NAMESPACE_MINIO             := minio
NAMESPACE_INGRESS           := ingress-nginx
NAMESPACE_PROMETHEUS        := monitoring
NAMESPACE_VICTORIA_METRICS  := monitoring
NAMESPACE_LOKI              := loki
NAMESPACE_GRAFANA           := grafana
NAMESPACE_JAEGER            := jaeger
NAMESPACE_OTEL_CLUSTER      := monitoring
NAMESPACE_OTEL_NODE         := monitoring
NAMESPACE_ARGOCD           := argocd

CHART_DEMO_APP          := ./helm/demo-app/
CHART_POSTGRES          := ./helm/postgres/
CHART_MINIO             := ./helm/minio/
CHART_INGRESS           := ./helm/ingress/
CHART_PROMETHEUS        := ./helm/prometheus/
CHART_VICTORIA_METRICS  := ./helm/victoria-metrics/
CHART_LOKI              := ./helm/loki/
CHART_GRAFANA           := ./helm/grafana/
CHART_JAEGER            := ./helm/jaeger/
CHART_OTEL_CLUSTER      := ./helm/otel-cluster/
CHART_OTEL_NODE         := ./helm/otel-node/
CHART_ARGOCD            := ./helm/argocd/

# SSH key used as the sops/age recipient for helm/*/secrets.enc.yaml.
# Override on the command line if your key lives elsewhere, e.g.:
#   make install-grafana SOPS_AGE_SSH_PRIVATE_KEY_FILE=~/.ssh/id_ed25519
SOPS_AGE_SSH_PRIVATE_KEY_FILE ?= ~/.ssh/id_rsa

create-cluster:
	kind create cluster --config kind.yaml

delete-cluster:
	kind delete cluster --name k8s-labs

install: install-postgres install-demo-app install-ingress install-minio install-grafana install-prometheus install-jaeger install-otel-node install-otel-cluster install-victoria-metrics

# Edit an encrypted secret in place (opens $EDITOR with decrypted content,
# re-encrypts on save). Usage: make edit-secret FILE=helm/grafana/secrets.enc.yaml
edit-secret:
	SOPS_AGE_SSH_PRIVATE_KEY_FILE=$(SOPS_AGE_SSH_PRIVATE_KEY_FILE) sops $(FILE)


install-demo-app:
	helm upgrade --install demo-app $(CHART_DEMO_APP) \
		--namespace $(NAMESPACE_DEMO_APP) \
		--create-namespace \
		--dependency-update

install-postgres:
	helm upgrade --install postgres $(CHART_POSTGRES) \
		--namespace $(NAMESPACE_POSTGRES) \
		--create-namespace \
		--dependency-update

install-ingress:
	helm upgrade --install ingress $(CHART_INGRESS) \
		--namespace $(NAMESPACE_INGRESS) \
		--create-namespace \
		--dependency-update

install-minio:
	helm upgrade --install minio $(CHART_MINIO) \
		--namespace $(NAMESPACE_MINIO) \
		--create-namespace \
		--dependency-update

install-prometheus:
	helm upgrade --install prometheus $(CHART_PROMETHEUS) \
		--namespace $(NAMESPACE_PROMETHEUS) \
		--create-namespace \
		--dependency-update

install-victoria-metrics:
	helm upgrade --install victoria-metrics $(CHART_VICTORIA_METRICS) \
		--namespace $(NAMESPACE_VICTORIA_METRICS) \
		--create-namespace \
		--dependency-update

install-loki:
	helm upgrade --install loki $(CHART_LOKI) \
		--namespace $(NAMESPACE_LOKI) \
		--create-namespace \
		--dependency-update

install-grafana:
	SOPS_AGE_SSH_PRIVATE_KEY_FILE=$(SOPS_AGE_SSH_PRIVATE_KEY_FILE) helm secrets upgrade --install grafana $(CHART_GRAFANA) \
		--namespace $(NAMESPACE_GRAFANA) \
		--create-namespace \
		--dependency-update \
		-f $(CHART_GRAFANA)values.yaml \
		-f $(CHART_GRAFANA)secrets.enc.yaml

install-jaeger:
	helm upgrade --install jaeger $(CHART_JAEGER) \
		--namespace $(NAMESPACE_JAEGER) \
		--create-namespace \
		--dependency-update

install-otel-cluster:
	helm upgrade --install otel-cluster $(CHART_OTEL_CLUSTER) \
		--namespace $(NAMESPACE_OTEL_CLUSTER) \
		--create-namespace \
		--dependency-update

install-otel-node:
	helm upgrade --install otel-node $(CHART_OTEL_NODE) \
		--namespace $(NAMESPACE_OTEL_NODE) \
		--create-namespace \
		--dependency-update

install-argocd:
	helm upgrade --install argocd $(CHART_ARGOCD) \
		--namespace $(NAMESPACE_ARGOCD) \
		--create-namespace \
		--dependency-update
