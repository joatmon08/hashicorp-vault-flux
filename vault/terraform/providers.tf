terraform {
  required_version = "~> 1.0"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.22"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.4"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 3.12"
    }
  }
}

provider "vault" {}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "gitlab" {}