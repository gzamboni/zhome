module "zcluster" {
  source               = "./zcluster"
  cluster_name         = var.k3s_config.cluster_name
  local_domain         = var.k3s_config.local_domain
  node_ssh_key         = file("~/.ssh/id_rsa.pub")
  nodes                = var.k3s_config.nodes
  node_users           = var.k3s_config.users
  metallb_address_pool = var.metallb_address_pool
}

module "dyndns" {
  source                      = "./dyndns"
  google_dynamic_dns_username = var.google_dynamic_dns_username
  google_dynamic_dns_password = var.google_dynamic_dns_password
  google_dynamic_dns_fqdn     = var.google_dynamic_dns_fqdn
}
