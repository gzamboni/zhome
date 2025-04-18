resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata.0.name

  # Wait for the release to be deployed
  wait = true

  # Set values for the Helm chart
  values = [
    yamlencode({
      server = {
        replicas = var.argocd_server_replicas
        service = {
          type = "LoadBalancer"
          annotations = {
            "metallb.io/address-pool" : "metallb-ip-pool"
            "metallb.universe.tf/ip-allocated-from-pool" = "metallb-ip-pool"
            "metallb.universe.tf/loadBalancerIPs"        = var.argocd_ip_address
          }
          externalTrafficPolicy = "Local"
        }
        resources = {
          limits = {
            cpu    = var.argocd_resources_limits_cpu
            memory = var.argocd_resources_limits_memory
          }
          requests = {
            cpu    = var.argocd_resources_requests_cpu
            memory = var.argocd_resources_requests_memory
          }
        }
        extraArgs = var.argocd_insecure ? ["--insecure"] : []
      }
      repoServer = {
        replicas = var.argocd_repo_server_replicas
        resources = {
          limits = {
            cpu    = var.argocd_resources_limits_cpu
            memory = var.argocd_resources_limits_memory
          }
          requests = {
            cpu    = var.argocd_resources_requests_cpu
            memory = var.argocd_resources_requests_memory
          }
        }
      }
      controller = {
        replicas = var.argocd_application_controller_replicas
        resources = {
          limits = {
            cpu    = var.argocd_resources_limits_cpu
            memory = var.argocd_resources_limits_memory
          }
          requests = {
            cpu    = var.argocd_resources_requests_cpu
            memory = var.argocd_resources_requests_memory
          }
        }
      }
      dex = {
        enabled = var.argocd_dex_enabled
      }
      ha = {
        enabled = var.argocd_ha_enabled
      }
      configs = {
        secret = {
          # Set admin password if provided
          argocdServerAdminPassword = var.argocd_admin_password != "" ? var.argocd_admin_password : null
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Create ArgoCD Projects
resource "kubectl_manifest" "argocd_project" {
  for_each = { for project in var.argocd_projects : project.name => project }

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = each.value.name
      namespace = kubernetes_namespace.argocd.metadata.0.name
    }
    spec = {
      description = lookup(each.value, "description", "Project ${each.value.name}")
      sourceRepos = lookup(each.value, "source_repos", ["*"])
      destinations = [
        for dest in lookup(each.value, "destinations", [{ server = "https://default.k3s.zhome.local", namespace = "*" }]) : {
          server    = dest.server
          namespace = dest.namespace
        }
      ]
      clusterResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
      namespaceResourceWhitelist = [
        {
          group = "*"
          kind  = "*"
        }
      ]
    }
  })

  depends_on = [
    helm_release.argocd
  ]
}

# Create a secret for the admin password if provided
resource "kubernetes_secret" "argocd_admin_password" {
  count = var.argocd_admin_password != "" ? 1 : 0

  metadata {
    name      = "argocd-admin-password"
    namespace = kubernetes_namespace.argocd.metadata.0.name
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    # The password will be bcrypt hashed by ArgoCD
    password = var.argocd_admin_password
  }

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Create repository secrets directly as Kubernetes resources
resource "kubernetes_secret" "argocd_repositories" {
  for_each = { for repo in var.argocd_repositories : repo.name => repo }

  metadata {
    name      = "repo-${each.key}"
    namespace = kubernetes_namespace.argocd.metadata.0.name
    labels = {
      "app.kubernetes.io/part-of"      = "argocd"
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = each.value.url
    name          = each.value.name
    username      = lookup(each.value, "username", "")
    password      = lookup(each.value, "password", "")
    sshPrivateKey = lookup(each.value, "ssh_key", "")
  }

  depends_on = [
    helm_release.argocd
  ]
}
