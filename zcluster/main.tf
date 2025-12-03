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

# NFS module for each node - server on zcm03, clients on other nodes
module "zcluster_nfs" {
  for_each               = var.nodes
  source                 = "./nfs"
  node_ip                = each.value.ip
  node_hostname          = each.key
  nodes_hosts            = var.nodes
  nfs_server_hostname    = "zcm03"
  nfs_server_ip          = var.nodes["zcm03"].ip
  nfs_client_nodes       = ["zcm01", "zcm02", "zcm04"]
  nfs_export_base_path   = "/mnt/k3s_data"
  nfs_client_mount_point = "/var/k3s"
  network_cidr           = "192.168.0.0/255.255.255.0"
  depends_on             = [module.zcluster_nodes]
}

# K3s module - uses /var/k3s as data directory which is mounted from NFS
module "k3s" {
  source     = "./k3s"
  nodes      = var.nodes
  ssh_key    = file("~/.ssh/id_rsa")
  k3s_user   = "k3s"
  depends_on = [module.zcluster_nodes, module.zcluster_nfs]
}

# MetalLB load balancer for Kubernetes services
module "loadbalancer_metallb" {
  source       = "./metallb"
  namespace    = "metallb-system"
  address_pool = var.metallb_address_pool
  depends_on   = [module.k3s]
}

# Longhorn storage for persistent volumes
module "pvc_storage_manager" {
  source               = "./longhorn"
  namespace            = "longhorn-storage"
  data_path            = "/storage"
  cifs_backup_user     = var.cifs_backup_user
  cifs_backup_password = var.cifs_backup_password
  cifs_backup_target   = var.cifs_backup_target
  depends_on           = [module.loadbalancer_metallb]
}
