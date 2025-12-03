output "master_node" {
  description = "The master node hostname and IP"
  value = {
    hostname = local.master_hostname
    ip       = local.master.ip
  }
}

output "worker_nodes" {
  description = "The worker nodes hostnames and IPs"
  value = {
    for hostname, data in local.workers : hostname => {
      ip   = data.ip
      type = data.type
    }
  }
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = "~/.kube/config-k3s"
}

output "k3s_version" {
  description = "Version of K3s installed"
  value       = "latest" # This could be improved by getting the actual version from the nodes
}

output "k3s_data_dir" {
  description = "Data directory used by K3s"
  value       = "/var/k3s"
}
