terraform {
  required_version = ">=0.13"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
  }
}

resource "random_string" "admin_token" {
  length  = 35
  special = false
}

resource "kubernetes_namespace" "vaultwarden_namespace" {
  metadata {
    name = "vaultwarden"
  }
}

resource "helm_release" "vaultwarden" {
  name            = "vaultwarden"
  repository      = ""
  chart           = "https://github.com/gabe565/charts/releases/download/vaultwarden-0.16.0/vaultwarden-0.16.0.tgz"
  namespace       = kubernetes_namespace.vaultwarden_namespace.metadata[0].name
  cleanup_on_fail = true
  set {
    name  = "env.ADMIN_TOKEN"
    value = random_string.admin_token.result
  }
  set {
    name  = "env.TZ"
    value = var.timezone
  }
  set {
    name  = "env.ALLOW_SIGNUPS"
    value = var.allow_signups ? "true" : "false"
  }
  set {
    name  = "env.SIGNUPS_DOMAINS_WHITELIST"
    value = join(",", var.domain_white_list)
  }
  set {
    name  = "env.ORG_CREATION_USERS"
    value = join(",", var.org_creation_users)
  }
  set {
    name  = "env.DOMAIN"
    value = var.default_vault_domain
  }
  set {
    name  = "env.SMTP_HOST"
    value = var.smtp_config.server.host
  }
  set {
    name  = "env.SMTP_FROM"
    value = var.smtp_config.email_config.from
  }
  set {
    name  = "env.SMTP_FROM_NAME"
    value = var.smtp_config.email_config.from_name
  }
  set {
    name  = "env.SMTP_SECURITY"
    value = var.smtp_config.server.security
  }
  set {
    name  = "env.SMTP_USERNAME"
    value = var.smtp_config.auth.username
  }
  set {
    name  = "env.SMTP_PASSWORD"
    value = var.smtp_config.auth.password
  }
  set {
    name  = "env.SMTP_EMBED_IMAGES"
    value = var.smtp_config.email_config.embed_images ? "true" : "false"
  }
  set {
    name  = "image.tag"
    value = "latest-alpine"
  }
  set {
    name  = "persistence.data.enabled"
    value = "true"
  }
  set {
    name  = "persistence.data.storageClass"
    value = "longhorn"
  }
  set {
    name  = "persistence.data.accessMode"
    value = "ReadWriteOnce"
  }
  set {
    name  = "persistence.data.size"
    value = "2Gi"
  }
  set {
    name  = "ingress.main.enabled"
    value = "true"
  }
  set {
    name  = "ingress.main.ingressClassName"
    value = "traefik"
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].host"
      value = set.value
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[0].path"
      value = "/"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[0].pathType"
      value = "Prefix"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[0].service.port"
      value = "8080"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[1].path"
      value = "/notifications/hub/negotiate"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[1].pathType"
      value = "Prefix"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[1].service.port"
      value = "8080"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[2].path"
      value = "/notifications/hub"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[2].pathType"
      value = "Prefix"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[2].service.port"
      value = "3012"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[3].path"
      value = "/api"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[3].pathType"
      value = "Prefix"
    }
  }
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.main.hosts[${set.key}].paths[3].service.port"
      value = "8080"
    }
  }
}
