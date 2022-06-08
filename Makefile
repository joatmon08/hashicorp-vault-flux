ingress:
	helm upgrade --install ingress-nginx ingress-nginx \
		--repo https://kubernetes.github.io/ingress-nginx \
		--namespace ingress-nginx --create-namespace

flux-bootstrap:
	flux bootstrap github \
		--owner=joatmon08 \
		--repository=hashicorp-vault-flux \
		--path=clusters/local \
		--branch=main \
		--personal
	kubectl apply -f clusters/local/csi-source.yaml
	kubectl apply -f clusters/local/csi-helm.yaml
	kubectl apply -f clusters/local/hashicorp-source.yaml
	kubectl apply -f clusters/local/vault-serviceaccounts.yaml
	kubectl apply -f clusters/local/vault-helm.yaml
	kubectl apply -f clusters/local/application-bootstrap-source.yaml
	kubectl apply -f clusters/local/database-kustomization.yaml
	kubectl apply -f clusters/local/vault-kustomization.yaml

vault-init:
	kubectl exec -ti vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > unseal.json
	kubectl exec -ti vault-0 -- vault operator unseal

vault-configure:
	cd vault/terraform && terraform init
	cd vault/terraform && terraform apply

flux-token:
	kubectl apply -f clusters/local/repository-kustomization.yaml

applications:
	kubectl apply -f clusters/local/hashicups-source.yaml
	kubectl apply -f clusters/local/hashicups-kustomization.yaml
	flux reconcile source git hashicups -n flux-system

clean:
	vault lease revoke -f -prefix hashicups/database/creds/product || true

	flux delete -s kustomization hashicups -n flux-system || true
	flux delete -s source git hashicups -n flux-system || true

	flux delete -s kustomization database -n flux-system || true
	flux delete -s kustomization repository -n flux-system || true
	flux delete -s source git application-bootstrap -n flux-system || true

	vault lease revoke -f -prefix hashicups/flux/data/gitlab || true
	cd vault/terraform && terraform destroy -auto-approve || true

	flux delete -s hr vault -n default || true
	flux delete -s hr csi -n default || true
	kubectl delete pvc --all

	flux delete -s source helm hashicorp -n default || true
	flux delete -s source helm secrets-store-csi-driver -n default || true
	flux uninstall -s -n flux-system

	helm del ingress-nginx -n ingress-nginx