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
	kubectl apply -f clusters/local/vault-helm.yaml
	kubectl apply -f clusters/local/application-bootstrap-source.yaml
	kubectl apply -f clusters/local/database-kustomization.yaml

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

clean:
	vault lease revoke -f -prefix hashicups/database/creds/product

	flux delete kustomization hashicups -n flux-system
	flux delete source git hashicups -n flux-system

	flux delete kustomization database -n flux-system
	flux delete kustomization repository -n flux-system
	flux delete source git application-bootstrap -n flux-system

	vault lease revoke -f -prefix hashicups/flux/data/gitlab
	cd vault/terraform && terraform destroy

	flux delete hr vault -n default
	flux delete hr csi -n default
	kubectl delete pvc --all

	flux delete source helm hashicorp -n default
	flux delete source helm secrets-store-csi-driver -n default
	flux uninstall -n flux-system

	helm del ingress-nginx -n ingress-nginx