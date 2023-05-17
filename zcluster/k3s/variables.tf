variable "nodes" {
  description = "value of the cluster nodes"
}

variable "k3s_user" {
  description = "k3s username to run services"
  default     = "k3s"
}

variable "ssh_key" {
  description = "ssh key to use for k3s user"
}
