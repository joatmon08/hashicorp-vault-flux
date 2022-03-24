locals {
  database_username = "postgres"
  database_password = "password"
  database_host     = "postgres"
  database_name     = "products"
  database_port     = 5432
}

variable "application" {
  type        = string
  description = "Name of application for base path"
  default     = "hashicups"
}

variable "service" {
  type        = string
  description = "Name of Kubernetes service for Vault role"
  default     = "product"
}

variable "service_account" {
  type        = string
  description = "Name of Kubernetes service account used for service"
  default     = "product-api"
}

variable "namespace" {
  type        = string
  description = "Name of Kubernetes namespace used for service"
  default     = "default"
}