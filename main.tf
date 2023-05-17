module "zcluster" {
  source       = "./zcluster"
  cluster_name = var.k3s_config.cluster_name
  local_domain = var.k3s_config.local_domain
  node_ssh_key = file("~/.ssh/id_rsa.pub")
  nodes        = var.k3s_config.nodes
  node_users   = var.k3s_config.users
}
