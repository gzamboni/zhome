resource "null_resource" "nodes" {
  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname ${var.node_hostname}.${var.node_local_domain}",
      "echo \"${templatefile("${path.module}/templates/hosts.tpl", { hostname = var.node_hostname, nodes = var.nodes_hosts, local_domain = var.node_local_domain })}\" > /etc/hosts",
      "chmod 644 /etc/hosts",
      "apt-get update && apt-get upgrade -y",
      "apt-get install -y apt-transport-https ca-certificates curl",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.node_ip
      port        = 22
      agent       = false
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

module "users" {
  for_each   = var.node_users
  source     = "./user"
  username   = each.value.username
  password   = each.value.password
  ssh_key    = var.node_ssh_key
  host_ip    = var.node_ip
  host_user  = var.node_admin_user
  depends_on = [null_resource.nodes]
}
