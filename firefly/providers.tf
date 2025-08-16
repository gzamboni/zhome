provider "kubernetes" {
  host        = "https://192.168.0.31:6443"
  config_path = "~/.kube/config"
}

provider "helm" {
  # For Helm provider 3.0.2, use direct configuration
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
