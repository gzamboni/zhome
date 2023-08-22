terraform {
  required_version = ">= 0.13.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
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

resource "kubernetes_storage_class" "longhorn_ssd" {
  metadata {
    name = "longhorn-ssd"
  }
  storage_provisioner = "driver.longhorn.io"
  parameters = {
    numberOfReplicas    = "1"
    staleReplicaTimeout = "480"
    diskSelector        = "ssd"
  }
}

resource "kubernetes_storage_class" "longhorn_nvme" {
  metadata {
    name = "longhorn-nvme"
  }
  storage_provisioner = "driver.longhorn.io"
  parameters = {
    numberOfReplicas    = "1"
    staleReplicaTimeout = "480"
    diskSelector        = "nvme"
  }
}

resource "kubernetes_secret" "longhorn_cifs_backup_user" {
  metadata {
    name      = "longhorn-cifs-backup-user"
    namespace = kubernetes_namespace.longhorn_storage.metadata[0].name
  }
  data = {
    CIFS_USERNAME = var.cifs_backup_user
    CIFS_PASSWORD = var.cifs_backup_password
  }
}

resource "kubectl_manifest" "longhorn_cifs_backup" {
  yaml_body  = <<-EOF
    apiVersion: longhorn.io/v1beta2
    kind: Setting
    metadata:
      name: backup-target
      namespace: ${kubernetes_namespace.longhorn_storage.metadata[0].name}
    value: ${var.cifs_backup_target}
    ---
    apiVersion: longhorn.io/v1beta2
    kind: Setting
    metadata:
      name: backup-target-credential-secret
      namespace: ${kubernetes_namespace.longhorn_storage.metadata[0].name}
    value: ${kubernetes_secret.longhorn_cifs_backup_user.metadata[0].name}
  EOF
  depends_on = [kubernetes_secret.longhorn_cifs_backup_user]
}
