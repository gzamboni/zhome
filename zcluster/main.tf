module "zcluster_nodes" {
  for_each          = var.nodes
  source            = "./node"
  node_ip           = each.value.ip
  node_hostname     = each.key
  node_local_domain = var.local_domain
  node_ssh_key      = file("~/.ssh/id_rsa.pub")
  nodes_hosts       = var.nodes
  node_users        = var.node_users
}

module "k3s" {
  source     = "./k3s"
  nodes      = var.nodes
  ssh_key    = file("~/.ssh/id_rsa")
  depends_on = [module.zcluster_nodes]
}

module "loadbalancer_metallb" {
  source       = "./metallb"
  namespace    = "metallb-system"
  address_pool = var.metallb_address_pool
  depends_on   = [module.k3s]
}

module "pvc_storage_manager" {
  source               = "./longhorn"
  namespace            = "longhorn-storage"
  data_path            = "/storage"
  cifs_backup_user     = var.cifs_backup_user
  cifs_backup_password = var.cifs_backup_password
  cifs_backup_target   = var.cifs_backup_target
  depends_on           = [module.loadbalancer_metallb]
}

module "prometheus" {
  source              = "./prometheus"
  domain              = "k3s.${var.local_domain}"
  default_smtp_config = var.default_smtp_config
  depends_on          = [module.pvc_storage_manager]
}
