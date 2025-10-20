
terraform {
  required_version = ">=0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.3"
    }

  }
}


provider "kubernetes" {
  config_path = "~/.kube/config"
}
