output "nfs_server_status" {
  description = "Status of the NFS server configuration"
  value       = length(null_resource.nfs_server) > 0 ? "configured" : "not configured"
}

output "nfs_client_status" {
  description = "Status of the NFS client configuration"
  value       = length(null_resource.nfs_client) > 0 ? "configured" : "not configured"
}

output "nfs_server_exports" {
  description = "List of NFS exports configured on the server"
  value = var.nfs_server_hostname == var.node_hostname ? [
    for node in var.nfs_client_nodes : "${var.nfs_export_base_path}/${node}"
  ] : []
}

output "nfs_client_mount" {
  description = "NFS mount point on the client"
  value       = contains(var.nfs_client_nodes, var.node_hostname) ? var.nfs_client_mount_point : ""
}
