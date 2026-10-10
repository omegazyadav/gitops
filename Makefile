CHART_ARGOCD            := ./helm/argocd/
NAMESPACE_ARGOCD        := argocd

ISTIO_VERSION           := 1.27.9

SOPS_AGE_SSH_PRIVATE_KEY_FILE ?= $(HOME)/.ssh/id_rsa

create-cluster:
	kind create cluster --config kind.yaml

delete-cluster:
	kind delete cluster --name k8s-labs

bootstrap:
	$(MAKE) install-argocd
	$(MAKE) install-tier TIER=istio

edit-secret:
	SOPS_AGE_SSH_PRIVATE_KEY_FILE=$(SOPS_AGE_SSH_PRIVATE_KEY_FILE) sops $(FILE)

# Istio's CRDs (Gateway/VirtualService/etc.) must exist before ArgoCD, since
# ArgoCD's own chart optionally renders a Gateway/VirtualService for itself.
# Applied directly (not via ArgoCD) to avoid the bootstrap chicken-and-egg:
# ArgoCD is what would otherwise install Istio. The full Istio control plane
# (istiod/ingressgateway) is still installed later, by ArgoCD, via
# `make install-tier TIER=istio` — this only pre-seeds the CRDs.
install-crds:
	kubectl create namespace istio-system --dry-run=client -o yaml \
		| kubectl label --local -f - istio-injection=enabled -o yaml \
		| kubectl apply -f -
	helm template istio-base base \
		--repo https://istio-release.storage.googleapis.com/charts \
		--version $(ISTIO_VERSION) \
		--namespace istio-system \
		| kubectl apply --server-side -f -

install-argocd: install-crds
	kubectl create namespace $(NAMESPACE_ARGOCD) --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n $(NAMESPACE_ARGOCD) create secret generic argocd-repo-server-age-key \
		--from-file=id_rsa=$(SOPS_AGE_SSH_PRIVATE_KEY_FILE) \
		--dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install argocd $(CHART_ARGOCD) \
		--namespace $(NAMESPACE_ARGOCD) \
		--create-namespace \
		--dependency-update
	kubectl apply -f apps/argocd/application.yaml

install-app:
	kubectl apply -f apps/$(APP)/application.yaml

uninstall-app:
	argocd app delete $(APP) --cascade --yes

install-tier:
	@for d in apps/*/; do \
		for f in $$d*.yaml; do \
			[ "$$(basename $$f)" = "kustomization.yaml" ] && continue; \
			if grep -q "tier: $(TIER)$$" $$f; then \
				kubectl apply -f $$f; \
			fi; \
		done; \
	done

uninstall-tier:
	@for d in apps/*/; do \
		for f in $$d*.yaml; do \
			[ "$$(basename $$f)" = "kustomization.yaml" ] && continue; \
			if grep -q "tier: $(TIER)$$" $$f; then \
				name=$$(grep "name:" $$f | head -1 | awk '{print $$2}'); \
				argocd app delete $$name --cascade --yes; \
			fi; \
		done; \
	done
