
resource "null_resource" "user" {
  count = 1
  provisioner "remote-exec" {
    inline = [
      "id ${var.username} || adduser --disabled-password --gecos '' ${var.username}",
      "echo ${var.username}:${var.password} | chpasswd",
      "mkdir -p /home/${var.username}/.ssh",
      "touch /home/${var.username}/.ssh/authorized_keys",
      "echo '${var.ssh_key}' > authorized_keys",
      "mv authorized_keys /home/${var.username}/.ssh",
      "chown -R ${var.username}:${var.username} /home/${var.username}/.ssh",
      "chmod 700 /home/${var.username}/.ssh",
      "chmod 600 /home/${var.username}/.ssh/authorized_keys",
      "usermod -aG sudo ${var.username}"
    ]
    connection {
      type        = "ssh"
      user        = var.host_user
      host        = var.host_ip
      port        = 22
      agent       = false
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

# Add User to Sudors without password
resource "null_resource" "sudo" {
  count = 1
  provisioner "remote-exec" {
    inline = [
      "echo '${var.username} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
    ]
    connection {
      type        = "ssh"
      user        = var.host_user
      host        = var.host_ip
      port        = 22
      agent       = false
      private_key = file("~/.ssh/id_rsa")
    }
  }
  # depends_on = [null_resource.user]
}
