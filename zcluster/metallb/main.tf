terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

locals {
  address_pool_name = var.address_pool.name
  address_pool      = var.address_pool.addresses
}

resource "kubernetes_namespace" "metal_lb_namespace" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "metal_lb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = kubernetes_namespace.metal_lb_namespace.metadata[0].name
  version    = "0.13.10"
}

resource "kubectl_manifest" "metal_lb_address_pool" {
  yaml_body  = <<-EOF
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    name: ${local.address_pool_name}
    namespace: ${var.namespace}
  spec:
    addresses:
    %{for address in local.address_pool}
    - ${address}
    %{endfor}
  EOF
  depends_on = [resource.helm_release.metal_lb]
}

resource "kubectl_manifest" "metal_lb_L2Advertisement" {
  yaml_body  = <<-EOF
  apiVersion: metallb.io/v1beta1
  kind: L2Advertisement
  metadata:
    name: ${var.l2_advertisement_name}
    namespace: ${var.namespace}
  spec:
    ipAddressPools:
    - ${var.address_pool.name}
  EOF
  depends_on = [resource.kubectl_manifest.metal_lb_address_pool]
}
