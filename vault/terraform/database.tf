resource "vault_mount" "postgres" {
  path = "${var.application}/database"
  type = "database"
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.postgres.path
  name          = var.service
  allowed_roles = [var.service]
  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${local.database_host}:${local.database_port}/${local.database_name}?sslmode=disable"
  }

  data = {
    username = local.database_username
    password = local.database_password
  }
}

resource "vault_database_secret_backend_role" "postgres" {
  backend               = vault_mount.postgres.path
  name                  = var.service
  db_name               = vault_database_secret_backend_connection.postgres.name
  creation_statements   = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"]
  revocation_statements = ["ALTER ROLE \"{{name}}\" NOLOGIN;"]
  default_ttl           = 3600
  max_ttl               = 3600
}

locals {
  database_creds_path = "${vault_mount.postgres.path}/creds/${var.service}"
}

data "vault_policy_document" "product" {
  rule {
    path         = local.database_creds_path
    capabilities = ["read"]
    description  = "read all ${var.service}"
  }
}

resource "vault_policy" "product" {
  name   = var.service
  policy = data.vault_policy_document.product.hcl
}

resource "vault_kubernetes_auth_backend_role" "product" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = var.service
  bound_service_account_names      = [var.service_account]
  bound_service_account_namespaces = [var.namespace]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.product.name]
}