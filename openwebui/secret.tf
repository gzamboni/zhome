resource "kubernetes_secret" "openwebui_oidc" {
  metadata {
    name      = "${var.namespace}-oidc"
    namespace = kubernetes_namespace.openwebui.metadata[0].name
  }

  data = {
    OAUTH_CLIENT_SECRET = var.oauth_client_secret
  }

  type = "Opaque"
}
