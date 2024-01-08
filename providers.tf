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
  }
}

locals {
  master_node = [for node, data in var.k3s_config.nodes : data if data.type == "master"][0]
  master_url  = "https://${local.master_node.ip}:6443"
}

provider "kubernetes" {
  config_path    = var.kubeconfig
  config_context = var.k3s_config.context
  host           = local.master_url
}

provider "kubectl" {
  config_path    = var.kubeconfig
  config_context = var.k3s_config.context
  host           = local.master_url
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig
    config_context = var.k3s_config.context
    host           = local.master_url
  }
}
