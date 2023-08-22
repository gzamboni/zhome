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

resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name            = "argocd"
  repository      = "https://argoproj.github.io/argo-helm"
  chart           = "argo-cd"
  namespace       = kubernetes_namespace.argocd_namespace.metadata[0].name
  cleanup_on_fail = true
  depends_on      = [kubernetes_namespace.argocd_namespace]
  set {
    name  = "params.server.insecure"
    value = "true"
  }
}

resource "kubectl_manifest" "argocd_ingress" {
  yaml_body = <<-YAML
  apiVersion: traefik.containo.us/v1alpha1
  kind: IngressRoute
  metadata:
    name: argocd-server
    namespace: argocd
  spec:
    entryPoints:
      - websecure
    routes:
      - kind: Rule
        match: Host(`argocd.k3s.zhome.local`)
        priority: 10
        services:
          - name: argocd-server
            port: 80
      - kind: Rule
        match: Host(`argocd.k3s.zhome.local`) && Headers(`Content-Type`, `application/grpc`)
        priority: 11
        services:
          - name: argocd-server
            port: 80
            scheme: h2c
    tls:
      certResolver: default
  YAML
}
