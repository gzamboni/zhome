variable "node_ip" {
  description = "IP address of the current node"
  type        = string
}

variable "node_hostname" {
  description = "Hostname of the current node"
  type        = string
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.node_hostname))
    error_message = "Invalid hostname"
  }
}

variable "nodes_hosts" {
  description = "Map of all nodes in the cluster"
  type = map(object({
    ip   = string
    type = string
  }))
}

variable "nfs_server_hostname" {
  description = "Hostname of the NFS server node (e.g., zcm03)"
  type        = string
  default     = "zcm03"
}

variable "nfs_server_ip" {
  description = "IP address of the NFS server"
  type        = string
}

variable "nfs_client_nodes" {
  description = "List of hostnames for nodes that will mount NFS shares"
  type        = list(string)
  default     = ["zcm01", "zcm02", "zcm04"]
}

variable "nfs_export_base_path" {
  description = "Base path on the NFS server for exports"
  type        = string
  default     = "/mnt/k3s_data"
}

variable "nfs_client_mount_point" {
  description = "Mount point on client nodes"
  type        = string
  default     = "/var/k3s"
}

variable "network_cidr" {
  description = "Network CIDR for NFS exports"
  type        = string
  default     = "192.168.0.0/255.255.255.0"
}

