locals {
  flux_username = "flux"
}

resource "gitlab_project" "hashicups" {
  name        = "hashicups"
  description = "Codebase for HashiCups"

  visibility_level = "private"
}

resource "gitlab_deploy_token" "hashicups" {
  depends_on = [gitlab_project.hashicups]
  project    = gitlab_project.hashicups.id
  name       = "Deploy Token for Flux"
  username   = local.flux_username

  scopes = ["read_repository", "read_registry"]
}

resource "vault_mount" "flux" {
  path        = "${var.application}/flux"
  type        = "kv-v2"
  description = "For ${var.application} Flux deploy secrets"
}

resource "vault_generic_secret" "gitlab" {
  path = "${vault_mount.flux.path}/gitlab"

  data_json = jsonencode({
    username = "${gitlab_deploy_token.hashicups.username}"
    password = "${gitlab_deploy_token.hashicups.token}"
  })
}

locals {
  gitlab_creds_path                      = "${vault_mount.flux.path}/data/gitlab"
  flux_source_controller_service_account = "source-controller"
  flux_namespace                         = "flux-system"
}

data "vault_policy_document" "gitlab" {
  rule {
    path = local.gitlab_creds_path

    capabilities = [
      "read"
    ]

    description = "read GitLab credentials"
  }
}

resource "vault_policy" "gitlab" {
  name   = "gitlab"
  policy = data.vault_policy_document.gitlab.hcl
}

resource "vault_kubernetes_auth_backend_role" "gitlab" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "flux"
  bound_service_account_names      = [local.flux_source_controller_service_account]
  bound_service_account_namespaces = [local.flux_namespace]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.gitlab.name]
}