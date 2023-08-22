terraform {
  required_version = ">=0.13"
  required_providers {

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.20.0"
    }
  }
}

resource "kubernetes_namespace" "n8n" {
  metadata {
    name = "n8n"
  }
}
