terraform {
  required_version = ">=0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

resource "kubernetes_namespace" "inadyn" {
  metadata {
    name = "inadyn"
    labels = {
      app = "inadyn"
    }
  }
}

resource "helm_release" "inadyn" {
  name            = "inadyn"
  repository      = "https://charts.philippwaller.com"
  chart           = "inadyn"
  namespace       = kubernetes_namespace.inadyn.metadata[0].name
  cleanup_on_fail = true
  depends_on      = [kubernetes_namespace.inadyn]
  set {
    name  = "inadynConfig"
    value = <<-EOF
    # Inadyn v2.0 configuration file format
    period          = 300

    provider default@domains.google.com {
        ssl         = true
        username    = ${var.google_dynamic_dns_username}
        password    = ${var.google_dynamic_dns_password}
        hostname    = ${var.google_dynamic_dns_fqdn}
    }
    EOF
  }
}
