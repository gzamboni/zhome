terraform {
  required_version = ">= 0.13.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

resource "kubernetes_namespace" "longhorn_storage" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "longhorn_storage" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = kubernetes_namespace.longhorn_storage.metadata[0].name
  depends_on = [kubernetes_namespace.longhorn_storage]
  timeout    = 1200

  set {
    name  = "defaultSettings.defaultDataPath"
    value = var.data_path
  }
  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.annotations.kubernetes.io/ingress.class"
    value = "traefik"
  }
  set {
    name  = "ingress.host"
    value = "longhorn.${var.domain}"
  }
}

resource "kubernetes_storage_class" "longhorn_external" {
  metadata {
    name = "longhorn-external"
  }
  storage_provisioner = "driver.longhorn.io"
  parameters = {
    numberOfReplicas    = "1"
    staleReplicaTimeout = "480"
    diskSelector        = "external"
  }
}
