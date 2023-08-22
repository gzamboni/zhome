terraform {
  required_version = ">=0.13"
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
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
