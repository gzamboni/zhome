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

  values = [
    <<-EOT
    defaultSettings:
      defaultDataPath: ${var.data_path}
      backupTarget: ${var.cifs_backup_target}
      backupTargetCredentialSecret: ${kubernetes_secret.longhorn_cifs_backup_user.metadata[0].name}
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: traefik
      host: longhorn.${var.domain}
    EOT
  ]
}

# Storage class is managed by the Longhorn Helm chart
# Removed to avoid conflicts with the Longhorn operator

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

# Backup settings are now configured directly in the Helm chart values
