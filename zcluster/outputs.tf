# Node outputs
output "nodes" {
  description = "Information about all nodes in the cluster"
  value = {
    for hostname, node in var.nodes : hostname => {
      ip   = node.ip
      type = node.type
    }
  }
}

# NFS outputs
output "nfs_server" {
  description = "NFS server information"
  value = {
    hostname    = "zcm03"
    ip          = var.nodes["zcm03"].ip
    export_path = "/mnt/k3s_data"
  }
}

output "nfs_clients" {
  description = "NFS client information"
  value = {
    for hostname in ["zcm01", "zcm02", "zcm04"] : hostname => {
      mount_point = "/var/k3s"
      server      = var.nodes["zcm03"].ip
    }
  }
}

# K3s outputs
output "k3s_master" {
  description = "K3s master node information"
  value = {
    hostname = module.k3s.master_node.hostname
    ip       = module.k3s.master_node.ip
  }
}

output "k3s_workers" {
  description = "K3s worker nodes information"
  value       = module.k3s.worker_nodes
}

output "k3s_kubeconfig" {
  description = "Path to the kubeconfig file"
  value       = module.k3s.kubeconfig_path
}

# MetalLB outputs
output "metallb_address_pool" {
  description = "MetalLB address pool configuration"
  value       = var.metallb_address_pool
}

# Longhorn outputs
output "longhorn_storage" {
  description = "Longhorn storage information"
  value = {
    namespace = "longhorn-storage"
    data_path = "/storage"
  }
}
