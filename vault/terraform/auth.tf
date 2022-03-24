data "kubernetes_service_account" "vault_auth" {
  metadata {
    name = "vault"
  }
}

data "kubernetes_secret" "vault_auth" {
  metadata {
    name = data.kubernetes_service_account.vault_auth.default_secret_name
  }
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = "https://kubernetes.docker.internal:6443"
  kubernetes_ca_cert = data.kubernetes_secret.vault_auth.data["ca.crt"]
  token_reviewer_jwt = data.kubernetes_secret.vault_auth.data.token
  issuer             = "https://kubernetes.default.svc.cluster.local"
}